import Foundation

/// A named, directly reachable app state ("kitchen/stove/flambe").
/// Routes are the only way the recorder reaches nested content.
public struct Route: Sendable {
    public let path: String
    public let summary: String
    /// Seconds of footage the take needs after `ready`. Recorder default.
    public let duration: Double
    public let tags: [String]
    let run: @MainActor @Sendable (Take) async throws -> Void

    public init(_ path: String, _ summary: String = "", duration: Double = 8,
                tags: [String] = [],
                run: @escaping @MainActor @Sendable (Take) async throws -> Void) {
        self.path = path; self.summary = summary
        self.duration = duration; self.tags = tags; self.run = run
    }
}

/// Collects routes. Groups prefix child paths so deep scenes stay readable.
@MainActor
public final class RouteBook {
    public private(set) var routes: [String: Route] = [:]
    private var prefix: [String] = []

    public init() {}

    public func add(_ route: Route) {
        let full = (prefix + [route.path]).joined(separator: "/")
        routes[full] = Route(full, route.summary, duration: route.duration,
                             tags: route.tags, run: route.run)
    }

    public func route(_ path: String, _ summary: String = "", duration: Double = 8,
                      tags: [String] = [],
                      _ run: @escaping @MainActor @Sendable (Take) async throws -> Void) {
        add(Route(path, summary, duration: duration, tags: tags, run: run))
    }

    public func group(_ name: String, _ body: (RouteBook) -> Void) {
        prefix.append(name); body(self); prefix.removeLast()
    }

    /// Exact match, else unique suffix match ("flambe" finds "kitchen/stove/flambe").
    public func resolve(_ path: String) -> Route? {
        if let r = routes[path] { return r }
        let hits = routes.values.filter { $0.path.hasSuffix("/" + path) }
        return hits.count == 1 ? hits[0] : nil
    }

    public var manifest: [[String: Any]] {
        routes.values.sorted { $0.path < $1.path }.map {
            ["path": $0.path, "summary": $0.summary,
             "duration": $0.duration, "tags": $0.tags]
        }
    }
}
