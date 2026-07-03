import AppKit
import Carbon

/// Orchestrates the Grid UI, subdivision logic, and mouse movement commands.
@MainActor
class GridController: NSObject {
    static let shared = GridController()

    // MARK: - UI Components
    var window: OverlayWindow?
    var gridView: GridView?

    // MARK: - State
    var currentRegion: Region?
    private var currentScreenIndex: Int = 0
    private var regionHistory: [Region] = []

    private override init() {
        super.init()
    }

    // MARK: - Lifecycle

    func show() {
        let screens = NSScreen.screens
        let currentScreen = screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? screens[0]

        if let idx = screens.firstIndex(of: currentScreen) {
            currentScreenIndex = idx
        }

        if window == nil {
            window = OverlayWindow(contentRect: currentScreen.frame, interactive: false)
            gridView = GridView(frame: NSRect.zero)
            window?.contentView = gridView
        }

        window?.setFrame(currentScreen.frame, display: false)
        resetRegion(for: currentScreen)

        window?.level = NSWindow.Level.screenSaver
        window?.orderFrontRegardless()

        ClickEngine.shared.setEnabled(true)
    }

    func hide() {
        if ClickEngine.shared.isDragging {
            ClickEngine.shared.toggleDrag()
        }

        window?.orderOut(nil)
        ClickEngine.shared.setEnabled(false)
    }

    // MARK: - Navigation

    func resetRegion(for screen: NSScreen? = nil) {
        let activeScreen = screen ?? NSScreen.main!
        currentRegion = Region(x: 0, y: 0, width: activeScreen.frame.width, height: activeScreen.frame.height)
        gridView?.region = currentRegion
        regionHistory.removeAll()
    }

    func goBack() {
        guard !regionHistory.isEmpty else { return }
        currentRegion = regionHistory.removeLast()
        gridView?.region = currentRegion
        updateVisualsAndCursor()
    }

    func subdivide(_ cell: Int) {
        guard var region = currentRegion else { return }

        // Smart Nudging: If the area is too small to split, treat WASD as nudges
        let threshold: CGFloat = 60.0
        if region.width <= threshold || region.height <= threshold {
            nudge(cell: cell)
            return
        }

        regionHistory.append(region)
        let cw = region.width / 2
        let ch = region.height / 2
        let row = (cell <= 2) ? 1 : 0
        let col = (cell % 2 == 1) ? 0 : 1

        region = Region(x: region.x + CGFloat(col) * cw, y: region.y + CGFloat(row) * ch, width: cw, height: ch)
        currentRegion = region
        gridView?.region = currentRegion
        updateVisualsAndCursor()
    }

    private func nudge(cell: Int) {
        guard var region = currentRegion else { return }
        let stepX = region.width * 0.1
        let stepY = region.height * 0.1

        switch cell {
        case 1: region.y += stepY // W
        case 2: region.x += stepX // D
        case 3: region.x -= stepX // A
        case 4: region.y -= stepY // S
        default: break
        }

        if let winFrame = window?.frame {
            region.x = max(0, min(region.x, winFrame.width - region.width))
            region.y = max(0, min(region.y, winFrame.height - region.height))
        }

        currentRegion = region
        gridView?.region = currentRegion
        updateVisualsAndCursor()
    }

    // MARK: - Hardware Interaction

    func updateVisualsAndCursor() {
        guard let r = currentRegion, let w = window else { return }

        let cx = r.x + (r.width / 2)
        let cy = r.y + (r.height / 2)
        let gx = w.frame.origin.x + cx
        let gy = w.frame.origin.y + cy

        let screens = NSScreen.screens
        let primary = screens.first { $0.frame.origin == .zero } ?? screens[0]
        let flippedY = primary.frame.height - gy
        let point = CGPoint(x: gx, y: flippedY)

        CGWarpMouseCursorPosition(point)

        if ClickEngine.shared.isDragging {
            let source = CGEventSource(stateID: .hidSystemState)
            let drag = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged, mouseCursorPosition: point, mouseButton: .left)
            drag?.post(tap: .cghidEventTap)
        }
    }

    func switchToNextMonitor() {
        let screens = NSScreen.screens
        currentScreenIndex = (currentScreenIndex + 1) % screens.count
        let nextScreen = screens[currentScreenIndex]

        window?.setFrame(nextScreen.frame, display: false)
        resetRegion(for: nextScreen)
        window?.orderFrontRegardless()
    }
}
