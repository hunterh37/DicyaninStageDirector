#if canImport(RealityKit)
import RealityKit

public extension Entity {
    /// Slash path lookup by entity name: "Kitchen/Stove/Pan".
    func entity(at path: String) -> Entity? {
        var node: Entity? = self
        for part in path.split(separator: "/") {
            node = node?.children.first { $0.name == part } ?? node?.findEntity(named: String(part))
        }
        return node
    }

    /// Indented name tree to a depth. Used to dump scene structure into scene-tree.txt.
    func nameTree(depth: Int = 4, indent: String = "") -> String {
        var s = indent + (name.isEmpty ? "<unnamed>" : name)
        if !availableAnimations.isEmpty { s += "  [anims:\(availableAnimations.count)]" }
        s += "\n"
        guard depth > 0 else { return s }
        for c in children { s += c.nameTree(depth: depth - 1, indent: indent + "  ") }
        return s
    }

    /// Plays every baked animation on this entity and descendants.
    func playAllAnimations(loop: Bool = false) {
        for a in availableAnimations { playAnimation(loop ? a.repeat() : a) }
        for c in children { c.playAllAnimations(loop: loop) }
    }
}

public extension Director {
    /// Writes the RealityKit tree under `root` to director/scene-tree.txt.
    func dumpTree(_ root: Entity, depth: Int = 5) {
        try? root.nameTree(depth: depth)
            .write(to: markers.dir.appendingPathComponent("scene-tree.txt"), atomically: true, encoding: .utf8)
    }
}
#endif
