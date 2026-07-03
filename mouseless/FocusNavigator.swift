import Foundation
import AppKit

enum FocusDirection {
    case left, right, up, down
}

class FocusNavigator {
    static let shared = FocusNavigator()

    func navigate(_ direction: FocusDirection) {
        Task { @MainActor in
            guard let current = WindowManager.shared.currentSnapshot else {
                WindowManager.shared.captureIntent()
                return
            }

            let candidates = WindowManager.shared.availableCandidates
            let currentCenter = CGPoint(x: current.frame.midX, y: current.frame.midY)

            var bestTarget: WindowCandidate?
            var minDistance = CGFloat.greatestFiniteMagnitude

            for target in candidates where target.id != current.cgWindowID {
                let targetCenter = CGPoint(x: target.frame.midX, y: target.frame.midY)
                let vector = CGPoint(x: targetCenter.x - currentCenter.x, y: targetCenter.y - currentCenter.y)

                if isPointInCone(vector: vector, direction: direction) {
                    let dist = hypot(vector.x, vector.y)
                    if dist < minDistance {
                        minDistance = dist
                        bestTarget = target
                    }
                }
            }

            if let target = bestTarget {
                WindowManager.shared.lockCandidate(target)
                NSRunningApplication(processIdentifier: target.pid)?.activate()
            }
        }
    }

    private func isPointInCone(vector: CGPoint, direction: FocusDirection) -> Bool {
        let angle = atan2(vector.y, vector.x) // Standard math: y-up
        // Since Cocoa is y-up, but we often think of screens as y-down in algorithms:
        // Adjust based on coordinate system consistency

        switch direction {
        case .right: return abs(angle) < .pi / 4
        case .left:  return abs(angle) > 3 * .pi / 4
        case .up:    return angle < -(.pi / 4) && angle > -3 * (.pi / 4)
        case .down:  return angle > (.pi / 4) && angle < 3 * (.pi / 4)
        }
    }
}
