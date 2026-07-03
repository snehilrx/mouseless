import Foundation
import ApplicationServices
import SwiftUI

// MARK: - Accessibility Concurrency
extension AXUIElement: @retroactive @unchecked Sendable {}

// MARK: - View Extensions
extension View {
    func onKeyDown(action: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyDownHandler(action: action))
    }
}

struct KeyDownHandler: NSViewRepresentable {
    let action: (NSEvent) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = action
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
}
