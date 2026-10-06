import Foundation

/// File contract with the recorder: <Caches>/director/
///   routes.json          manifest of every route
///   <take>.ready|.done   lifecycle markers
///   <take>.cues.json     [{name, t}]
///   <take>.error         failure text
///   inbox.json           live command from the host (optional)
struct Markers {
    let dir: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        dir = caches.appendingPathComponent("director", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    func write(_ kind: String, take: String, body: String = "") {
        try? body.write(to: dir.appendingPathComponent("\(take).\(kind)"), atomically: true, encoding: .utf8)
    }

    func clear(take: String) {
        for k in ["ready", "done", "error", "cues.json"] {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(take).\(k)"))
        }
    }

    func cue(_ name: String, at t: Double, take: String) {
        let url = dir.appendingPathComponent("\(take).cues.json")
        var list = (try? Data(contentsOf: url))
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [[String: Any]] } ?? []
        list.append(["name": name, "t": (t * 100).rounded() / 100])
        if let d = try? JSONSerialization.data(withJSONObject: list) { try? d.write(to: url) }
    }

    func writeManifest(_ m: [[String: Any]]) {
        if let d = try? JSONSerialization.data(withJSONObject: m, options: [.prettyPrinted, .sortedKeys]) {
            try? d.write(to: dir.appendingPathComponent("routes.json"))
        }
    }

    func takeInbox() -> [String: String]? {
        let url = dir.appendingPathComponent("inbox.json")
        guard let d = try? Data(contentsOf: url),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String: String] else { return nil }
        try? FileManager.default.removeItem(at: url)
        return o
    }
}
