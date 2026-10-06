#if canImport(SwiftUI) && os(visionOS)
import SwiftUI

/// Attach to the first window's root view. Wires SwiftUI scene actions
/// into the Director and starts it. No-op without director launch args.
public struct DirectorHost: ViewModifier {
    @Environment(\.openImmersiveSpace) private var openImmersive
    @Environment(\.dismissImmersiveSpace) private var dismissImmersive
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    let register: (RouteBook) -> Void

    public func body(content: Content) -> some View {
        content.task {
            let d = Director.shared
            guard d.isDirecting else { return }
            var a = DirectorActions()
            a.openImmersive = { id in _ = await openImmersive(id: id) }
            a.dismissImmersive = { await dismissImmersive() }
            a.openWindow = { openWindow(id: $0) }
            a.dismissWindow = { dismissWindow(id: $0) }
            d.actions = a
            d.register(register)
            d.start()
        }
    }
}

public extension View {
    /// `.director { book in book.route("hero") { take in ... } }`
    func director(_ register: @escaping (RouteBook) -> Void) -> some View {
        modifier(DirectorHost(register: register))
    }
}
#endif
