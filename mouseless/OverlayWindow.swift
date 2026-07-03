import AppKit

/// A specialized NSPanel that doesn't steal focus, allowing the target application
/// to remain "active" while the grid or switcher is displayed.
class OverlayWindow: NSPanel {

    private let isInteractive: Bool

    init(contentRect: NSRect, interactive: Bool = false) {
        self.isInteractive = interactive
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver

        ignoresMouseEvents = !isInteractive
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        becomesKeyOnlyIfNeeded = isInteractive
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { isInteractive }
    override var canBecomeMain: Bool { isInteractive }
}
