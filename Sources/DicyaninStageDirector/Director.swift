import Foundation

/// Launch-arg control surface for demo recording.
///
///   -Route kitchen/stove/flambe   run a route
///   -Take 03-flambe               marker name (defaults to route path, "/" -> "-")
///   -Seed 7                       RNG seed
///   -P.<key> <value>              route params (e.g. -P.yaw -30)
///   -DirectorList YES             write routes.json and idle
///   -DirectorInbox YES            poll inbox.json for live {"route": ...} commands
///
/// Inactive unless one of these args is present. Wrap call sites in #if DEBUG.
@MainActor
public final class Director {
    public static let shared = Director()

    public let book = RouteBook()
    public var actions = DirectorActions()
    public private(set) var current: Take?
    /// True while a take runs. Apps hide debug chrome and skip onboarding on this.
    public var isDirecting: Bool { args.isActive }
    /// Systems read this to stop advancing simulation after `take.freeze()`.
    public var isFrozen: Bool { current?.isFrozen ?? false }

    let markers = Markers()
    let args: LaunchArgs
    private var started = false

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        args = LaunchArgs(arguments)
    }

    public func register(_ build: (RouteBook) -> Void) { build(book) }

    /// Call once after the root view appears and `actions` are wired.
    public func start() {
        guard !started else { return }
        started = true
        markers.writeManifest(book.manifest)
        if let path = args.route { Task { await play(path, take: args.take, seed: args.seed, params: args.params) } }
        if args.inbox { Task { await pollInbox() } }
    }

    public func play(_ path: String, take: String? = nil, seed: UInt64 = 1,
                     params: [String: String] = [:]) async {
        let id = take ?? path.replacingOccurrences(of: "/", with: "-")
        markers.clear(take: id)
        guard let route = book.resolve(path) else {
            markers.write("error", take: id, body: "unknown route \(path)")
            return
        }
        let t = Take(id: id, path: route.path, seed: seed, params: params,
                     markers: markers, actions: actions)
        current = t
        do {
            try await route.run(t)
            if !FileManager.default.fileExists(atPath: markers.dir.appendingPathComponent("\(id).ready").path) {
                await t.ready()
            }
            t.done()
        } catch {
            markers.write("error", take: id, body: "\(error)")
        }
    }

    private func pollInbox() async {
        while true {
            if let cmd = markers.takeInbox(), let r = cmd["route"] {
                var p = cmd; p.removeValue(forKey: "route"); p.removeValue(forKey: "take")
                await play(r, take: cmd["take"], seed: UInt64(cmd["seed"] ?? "1") ?? 1, params: p)
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }
}

struct LaunchArgs {
    var route: String?
    var take: String?
    var seed: UInt64 = 1
    var params: [String: String] = [:]
    var list = false
    var inbox = false
    var isActive: Bool { route != nil || list || inbox }

    init(_ a: [String]) {
        var i = 1
        while i < a.count {
            let k = a[i], v = i + 1 < a.count ? a[i + 1] : ""
            switch k {
            case "-Route": route = v
            case "-Take": take = v
            case "-Seed": seed = UInt64(v) ?? 1
            case "-DirectorList": list = v == "YES"
            case "-DirectorInbox": inbox = v == "YES"
            default:
                if k.hasPrefix("-P.") { params[String(k.dropFirst(3))] = v } else { i += 1; continue }
            }
            i += 2
        }
    }
}
