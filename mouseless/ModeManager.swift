import Foundation
import Combine
import AppKit

@MainActor
class ModeManager: ObservableObject {
    static let shared = ModeManager()

    @Published var currentMode: String = "main"

    func setMode(_ mode: String) {
        currentMode = mode
        print("[Mode] Switched to \(mode)")
    }

    func handleKey(keyCode: UInt16, isShift: Bool, isCmd: Bool) -> Bool {
        if keyCode == 53 { // ESC
            setMode("main")
            return true
        }

        switch currentMode {
        case "resize":
            return handleResizeMode(keyCode)
        case "layout":
            return handleLayoutMode(keyCode)
        default:
            return false
        }
    }

    private func handleResizeMode(_ code: UInt16) -> Bool {
        let step: CGFloat = 50
        switch code {
        case 4:  WindowManager.shared.adjustSize(dw: -step, dh: 0); return true // H
        case 38: WindowManager.shared.adjustSize(dw: 0, dh: step); return true  // J
        case 40: WindowManager.shared.adjustSize(dw: 0, dh: -step); return true // K
        case 37: WindowManager.shared.adjustSize(dw: step, dh: 0); return true  // L
        default: return false
        }
    }

    private func handleLayoutMode(_ code: UInt16) -> Bool {
        switch code {
        case 18: WindowManager.shared.applyLayout(.leftHalf); return true
        case 19: WindowManager.shared.applyLayout(.rightHalf); return true
        case 20: WindowManager.shared.applyLayout(.topHalf); return true
        case 21: WindowManager.shared.applyLayout(.bottomHalf); return true
        case 23: WindowManager.shared.applyLayout(.maximize); return true
        case 48: WindowManager.shared.moveToNextMonitor(); return true
        default: return false
        }
    }
}
