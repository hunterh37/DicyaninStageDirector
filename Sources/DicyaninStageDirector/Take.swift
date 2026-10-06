import Foundation

/// Handle passed to a route. Cues mark beats for the recorder and editor.
@MainActor
public final class Take {
    public let id: String
    public let path: String
    public let seed: UInt64
    public let params: [String: String]
    public var rng: SeededRNG
    let markers: Markers
    let started = Date()
    public internal(set) var isFrozen = false
    var actions: DirectorActions

    init(id: String, path: String, seed: UInt64, params: [String: String],
         markers: Markers, actions: DirectorActions) {
        self.id = id; self.path = path; self.seed = seed; self.params = params
        self.rng = SeededRNG(seed: seed); self.markers = markers; self.actions = actions
    }

    public func param(_ key: String) -> String? { params[key] }
    public func param(_ key: String, default d: Double) -> Double { params[key].flatMap(Double.init) ?? d }

    /// Scene is staged; recorder starts filming after this.
    public func ready() async {
        await waitFrames(30)
        markers.write("ready", take: id)
    }

    /// Named beat, logged with its time offset into cues.json.
    public func cue(_ name: String) {
        markers.cue(name, at: Date().timeIntervalSince(started), take: id)
    }

    /// Route finished; recorder stops after the tail.
    public func done() { markers.write("done", take: id) }

    public func wait(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    public func waitFrames(_ n: Int) async { await wait(Double(n) / 90.0) }

    public func freeze() { isFrozen = true }

    public func openImmersive(_ id: String) async { await actions.openImmersive?(id) }
    public func dismissImmersive() async { await actions.dismissImmersive?() }
    public func openWindow(_ id: String) { actions.openWindow?(id) }
    public func dismissWindow(_ id: String) { actions.dismissWindow?(id) }
}

/// SplitMix64. Deterministic across runs for a given seed.
public struct SeededRNG: RandomNumberGenerator, Sendable {
    var state: UInt64
    public init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public struct DirectorActions {
    public var openImmersive: (@MainActor (String) async -> Void)?
    public var dismissImmersive: (@MainActor () async -> Void)?
    public var openWindow: (@MainActor (String) -> Void)?
    public var dismissWindow: (@MainActor (String) -> Void)?
    public init() {}
}
