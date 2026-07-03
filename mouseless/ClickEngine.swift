import AppKit
import Carbon

/// Global Event Tap that shields the system from keys when Mouseless is active.
class ClickEngine {
    static let shared = ClickEngine()

    private var eventTap: CFMachPort?
    var isActive: Bool = false
    var isDragging: Bool = false

    func install() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) |
                   CGEventMask(1 << CGEventType.keyUp.rawValue) |
                   CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let engine = Unmanaged<ClickEngine>.fromOpaque(refcon).takeUnretainedValue()
                return engine.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        if let tap = eventTap {
            let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func setEnabled(_ enabled: Bool) {
        isActive = enabled
        if !enabled { isDragging = false }
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if event.flags.contains(.maskAlphaShift) {
            var flags = event.flags
            flags.remove(.maskAlphaShift)
            event.flags = flags
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // --- 1. System Intercepts ---

        if keyCode == 48 && event.flags.contains(.maskCommand) {
            Task { @MainActor in AppSwitcherController.shared.show() }
            return nil
        }

        if keyCode == 57 {
            if type == .flagsChanged {
                Task { @MainActor in
                    if GridController.shared.window?.isVisible == true {
                        GridController.shared.hide()
                    } else {
                        WindowManager.shared.captureIntent()
                        GridController.shared.show()
                    }
                }
            }
            return nil
        }

        // --- 2. Grid Intercepts ---

        if keyCode == 53 && isActive { // Esc
            if type == .keyDown { Task { @MainActor in GridController.shared.hide() } }
            return nil
        }

        guard isActive else { return Unmanaged.passRetained(event) }
        if type == .keyUp { return nil }

        if type == .flagsChanged {
            let isShift = event.flags.contains(.maskShift)
            Task { @MainActor in GridController.shared.gridView?.isShiftPressed = isShift }
            return nil
        }

        let isShift = event.flags.contains(.maskShift)
        let isAlt = event.flags.contains(.maskAlternate)
        let isCmd = event.flags.contains(.maskCommand)

        Task { @MainActor in
            _ = ModeManager.shared.handleKey(keyCode: UInt16(keyCode), isShift: isShift, isCmd: isCmd)
        }

        if keyCode == 34 { executeScroll(dx: 0, dy: 50); return nil } // I
        if keyCode == 38 && !isAlt { executeScroll(dx: -50, dy: 0); return nil } // J
        if keyCode == 40 && !isAlt { executeScroll(dx: 0, dy: -50); return nil } // K
        if keyCode == 37 && !isAlt { executeScroll(dx: 50, dy: 0); return nil } // L

        switch Int(keyCode) {
        // Navigation (Alt + HJKL)
        case 4:
            if isAlt { Task { @MainActor in FocusNavigator.shared.navigate(.left) } }
            else { Task { @MainActor in GridController.shared.gridView?.showHelp.toggle() } }
            return nil
        case 38: if isAlt { Task { @MainActor in FocusNavigator.shared.navigate(.down) }; return nil }
        case 40: if isAlt { Task { @MainActor in FocusNavigator.shared.navigate(.up) }; return nil }
        case 37: if isAlt { Task { @MainActor in FocusNavigator.shared.navigate(.right) }; return nil }

        case 49, 36: executeClick(button: .left) // Space / Enter
        case 48: // Tab
            if isShift { Task { @MainActor in WindowManager.shared.moveToNextMonitor() } }
            else { Task { @MainActor in GridController.shared.switchToNextMonitor() } }

        case 13: // W
            if isShift { Task { @MainActor in WindowManager.shared.applyLayout(.maximize) } }
            else { Task { @MainActor in GridController.shared.subdivide(1) } }
        case 2: // D
            if isShift { Task { @MainActor in WindowManager.shared.applyLayout(.rightHalf) } }
            else { Task { @MainActor in GridController.shared.subdivide(2) } }
        case 0: // A
            if isShift { Task { @MainActor in WindowManager.shared.applyLayout(.leftHalf) } }
            else { Task { @MainActor in GridController.shared.subdivide(3) } }
        case 1: // S
            if isShift { Task { @MainActor in WindowManager.shared.applyLayout(.bottomHalf) } }
            else { Task { @MainActor in GridController.shared.subdivide(4) } }

        case 11: Task { @MainActor in GridController.shared.goBack() } // B
        case 15: Task { @MainActor in GridController.shared.resetRegion() } // R
        case 7:  if isShift { Task { @MainActor in WindowManager.shared.applyLayout(.bottomRight) } } else { toggleDrag() } // X
        case 3:  if isShift { Task { @MainActor in WindowManager.shared.toggleFullscreen() } } else { executeClick(button: .right) } // F
        case 9:  executeClick(button: .left, count: 2) // V

        default: break
        }

        return nil
    }

    private func executeClick(button: CGMouseButton, count: Int = 1) {
        if isDragging { toggleDrag(); return }

        let pos = CGEvent(source: nil)!.location
        let source = CGEventSource(stateID: .hidSystemState)
        let down = (button == .left) ? CGEventType.leftMouseDown : CGEventType.rightMouseDown
        let up = (button == .left) ? CGEventType.leftMouseUp : CGEventType.rightMouseUp

        for i in 1...count {
            let d = CGEvent(mouseEventSource: source, mouseType: down, mouseCursorPosition: pos, mouseButton: button)
            d?.setIntegerValueField(.mouseEventClickState, value: Int64(i))
            d?.post(tap: .cghidEventTap)

            let u = CGEvent(mouseEventSource: source, mouseType: up, mouseCursorPosition: pos, mouseButton: button)
            u?.setIntegerValueField(.mouseEventClickState, value: Int64(i))
            u?.post(tap: .cghidEventTap)
        }

        Task { @MainActor in GridController.shared.hide() }
    }

    func toggleDrag() {
        let source = CGEventSource(stateID: .hidSystemState)
        let pos = CGEvent(source: nil)?.location ?? .zero

        if isDragging {
            let up = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: pos, mouseButton: .left)
            up?.post(tap: .cghidEventTap)
            isDragging = false
            Task { @MainActor in GridController.shared.hide() }
        } else {
            let down = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: pos, mouseButton: .left)
            down?.post(tap: .cghidEventTap)
            isDragging = true
        }

        Task { @MainActor in GridController.shared.gridView?.needsDisplay = true }
    }

    private func executeScroll(dx: Int32, dy: Int32) {
        let source = CGEventSource(stateID: .hidSystemState)
        let scroll = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0)
        scroll?.post(tap: .cghidEventTap)
    }
}
