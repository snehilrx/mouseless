import AppKit
@preconcurrency import ApplicationServices
import Foundation
import Combine

// MARK: - Private AX Helper
@_silgen_name("_AXUIElementGetWindow")
@discardableResult
func _AXUIElementGetWindow(_ element: AXUIElement, _ identifier: inout CGWindowID) -> AXError

// MARK: - Window Management Core

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    // MARK: - Published State
    @Published var currentSnapshot: WindowSnapshot?
    @Published var availableCandidates: [WindowCandidate] = []
    @Published var isResolving: Bool = false

    // MARK: - Internal Logic State
    private var currentCandidateIndex: Int = 0
    let axQueue = DispatchQueue(label: "com.snehil.mouseless.axQueue", qos: .userInteractive)
    private var axCache: [CGWindowID: AXUIElement] = [:]

    // MARK: - Enums
    enum WindowPosition {
        case leftHalf, rightHalf, topHalf, bottomHalf
        case topLeft, topRight, bottomLeft, bottomRight
        case leftThird, middleThird, rightThird
        case leftTwoThirds, rightTwoThirds
        case maximize, center
    }

    private init() {}

    // MARK: - Public API

    /// Captures the current visual state of all windows and locks the frontmost candidate.
    func captureIntent() {
        print("[WindowManager] 📸 Scanning visual stack...")
        let selfPID = getpid()
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return }

        let primaryHeight = axFlipHeight()
        var found: [WindowCandidate] = []

        for info in list {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid != selfPID,
                  let alpha = info[kCGWindowAlpha as String] as? Double, alpha > 0,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let cgBounds = CGRect(dictionaryRepresentation: boundsDict as NSDictionary),
                  cgBounds.width > 100, cgBounds.height > 100 else { continue }

            let wid = info[kCGWindowNumber as String] as? CGWindowID ?? 0
            let appName = info[kCGWindowOwnerName as String] as? String ?? "App"
            let title = info[kCGWindowName as String] as? String ?? ""
            let bundleID = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? ""

            // Normalize coordinate system immediately
            let cocoaFrame = CGRect(
                x: cgBounds.origin.x,
                y: primaryHeight - (cgBounds.origin.y + cgBounds.size.height),
                width: cgBounds.size.width,
                height: cgBounds.size.height
            )

            if isFloating(wid: wid, pid: pid, frame: cocoaFrame) { continue }
            found.append(WindowCandidate(id: wid, pid: pid, appName: appName, title: title, frame: cocoaFrame, bundleID: bundleID))
        }

        self.availableCandidates = found
        self.currentCandidateIndex = 0

        if let first = found.first {
            establishSnapshot(for: first)
        } else {
            self.currentSnapshot = nil
        }
    }

    /// Moves focus to the next available window candidate.
    func cycleNextCandidate() {
        guard !availableCandidates.isEmpty else { return }
        currentCandidateIndex = (currentCandidateIndex + 1) % availableCandidates.count
        establishSnapshot(for: availableCandidates[currentCandidateIndex])
        activateTargetApp()
    }

    /// Applies a specific layout position to the currently focused window.
    func applyLayout(_ position: WindowPosition) {
        guard let snap = currentSnapshot else { return }
        executeMove(snap.axWindow, position: position)
    }

    /// Toggles the native macOS fullscreen state for the currently focused window.
    func toggleFullscreen() {
        guard let snap = currentSnapshot else { return }
        axQueue.async {
            var val: CFTypeRef?
            if AXUIElementCopyAttributeValue(snap.axWindow, "AXFullScreen" as CFString, &val) == .success {
                let isFull = (val as? Bool) ?? false
                AXUIElementSetAttributeValue(snap.axWindow, "AXFullScreen" as CFString, !isFull as CFTypeRef)
            }
        }
    }

    /// Teleports the currently focused window to the same relative position on the next monitor.
    func moveToNextMonitor() {
        guard let snap = currentSnapshot else { return }
        guard let currentScreen = getScreenContaining(snap.axWindow) else { return }
        let screens = NSScreen.screens
        guard screens.count > 1, let idx = screens.firstIndex(of: currentScreen) else { return }
        let next = screens[(idx + 1) % screens.count]

        let nextFrame = next.visibleFrame
        let targetFrame = CGRect(
            x: nextFrame.origin.x + (nextFrame.width - snap.frame.width) / 2,
            y: nextFrame.origin.y + (nextFrame.height - snap.frame.height) / 2,
            width: min(snap.frame.width, nextFrame.width),
            height: min(snap.frame.height, nextFrame.height)
        )
        setWindowFrame(snap.axWindow, cocoaFrame: targetFrame)
    }

    /// Brings the target application of the focused window to the foreground.
    func activateTargetApp() {
        guard let snap = currentSnapshot else { return }
        NSRunningApplication(processIdentifier: snap.pid)?.activate(options: .activateIgnoringOtherApps)
    }

    /// Locks a specific candidate as the current target.
    func lockCandidate(_ candidate: WindowCandidate) {
        establishSnapshot(for: candidate)
    }

    // MARK: - Resolution Engine

    func resolveAXElement(for wid: CGWindowID) -> AXUIElement? {
        return axCache[wid]
    }

    private func establishSnapshot(for candidate: WindowCandidate) {
        self.isResolving = true

        let controllablePID = resolveControlPID(for: candidate.pid)
        let appAX = AXUIElementCreateApplication(controllablePID)
        AXUIElementSetMessagingTimeout(appAX, 0.5)

        var foundAX: AXUIElement?
        var val: CFTypeRef?

        // Strategy 1: Map visual WID to AX element
        if AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &val) == .success,
           let windows = val as? [AXUIElement] {
            foundAX = windows.first { w in
                var wid: CGWindowID = 0
                _AXUIElementGetWindow(w, &wid)
                return wid == candidate.id
            }
        }

        // Strategy 2: Fallback to focused window
        if foundAX == nil {
            if AXUIElementCopyAttributeValue(appAX, kAXFocusedWindowAttribute as CFString, &val) == .success {
                foundAX = (val as! AXUIElement)
            }
        }

        self.isResolving = false
        guard let win = foundAX else { return }

        axCache[candidate.id] = win

        let axFrame = axFrameOfWindow(win)
        let cocoaFrame = axFrame.map { axFrameToCocoa($0) } ?? candidate.frame

        self.currentSnapshot = WindowSnapshot(
            pid: controllablePID,
            axWindow: win,
            cgWindowID: candidate.id,
            appName: candidate.appName,
            frame: cocoaFrame,
            bundleID: candidate.bundleID
        )
    }

    // MARK: - Window Engine Logic

    private func executeMove(_ window: AXUIElement, position: WindowPosition) {
        guard let screen = getScreenContaining(window) else { return }
        let sf = screen.visibleFrame
        let gaps = ConfigParser.shared.config.gaps

        var usable = sf
        usable.origin.x += gaps.outerLeft
        usable.origin.y += gaps.outerBottom
        usable.size.width -= (gaps.outerLeft + gaps.outerRight)
        usable.size.height -= (gaps.outerTop + gaps.outerBottom)

        var f = usable
        switch position {
        case .leftHalf:
            f.size.width = (usable.width - gaps.inner) / 2
        case .rightHalf:
            f.size.width = (usable.width - gaps.inner) / 2
            f.origin.x = usable.origin.x + f.size.width + gaps.inner
        case .topHalf:
            f.size.height = (usable.height - gaps.inner) / 2
            f.origin.y = usable.origin.y + f.size.height + gaps.inner
        case .bottomHalf:
            f.size.height = (usable.height - gaps.inner) / 2
        case .topLeft:
            f.size.width = (usable.width - gaps.inner) / 2
            f.size.height = (usable.height - gaps.inner) / 2
            f.origin.y = usable.origin.y + f.size.height + gaps.inner
        case .topRight:
            f.size.width = (usable.width - gaps.inner) / 2
            f.size.height = (usable.height - gaps.inner) / 2
            f.origin.x = usable.origin.x + f.size.width + gaps.inner
            f.origin.y = usable.origin.y + f.size.height + gaps.inner
        case .bottomLeft:
            f.size.width = (usable.width - gaps.inner) / 2
            f.size.height = (usable.height - gaps.inner) / 2
        case .bottomRight:
            f.size.width = (usable.width - gaps.inner) / 2
            f.size.height = (usable.height - gaps.inner) / 2
            f.origin.x = usable.origin.x + f.size.width + gaps.inner
        case .leftThird:
            f.size.width = (usable.width - 2 * gaps.inner) / 3
        case .middleThird:
            f.size.width = (usable.width - 2 * gaps.inner) / 3
            f.origin.x = usable.origin.x + f.size.width + gaps.inner
        case .rightThird:
            f.size.width = (usable.width - 2 * gaps.inner) / 3
            f.origin.x = usable.origin.x + 2 * (f.size.width + gaps.inner)
        case .maximize: break
        case .center:
            f.size = CGSize(width: usable.width * 0.8, height: usable.height * 0.8)
            f.origin = CGPoint(x: usable.origin.x + (usable.width - f.size.width) / 2, y: usable.origin.y + (usable.height - f.size.height) / 2)
        default: break
        }
        setWindowFrame(window, cocoaFrame: f)
    }

    private func setWindowFrame(_ window: AXUIElement, cocoaFrame: CGRect) {
        let flipHeight = axFlipHeight()
        let axOrigin = CGPoint(x: cocoaFrame.origin.x, y: flipHeight - (cocoaFrame.origin.y + cocoaFrame.height))
        let axSize = cocoaFrame.size

        axQueue.async {
            WindowManager.performAXFrameWrite(window, origin: axOrigin, size: axSize)
            // Double-write pattern for reliability (resistance from apps like Chrome)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                WindowManager.performAXFrameWrite(window, origin: axOrigin, size: axSize)
            }
        }
    }

    nonisolated static func performAXFrameWrite(_ window: AXUIElement, origin: CGPoint, size: CGSize) {
        var o = origin, s = size
        if let pv = AXValueCreate(.cgPoint, &o) { AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pv) }
        if let sv = AXValueCreate(.cgSize, &s) { AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sv) }
    }

    nonisolated static func performAXPositionWrite(_ window: AXUIElement, point: CGPoint) {
        var p = point
        if let pv = AXValueCreate(.cgPoint, &p) { AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pv) }
    }

    /// Adjusts the size of the currently focused window by a delta.
    func adjustSize(dw: CGFloat, dh: CGFloat) {
        guard let snap = currentSnapshot else { return }
        let currentFrame = axFrameOfWindow(snap.axWindow).map { axFrameToCocoa($0) } ?? snap.frame
        var newFrame = currentFrame
        newFrame.size.width += dw
        newFrame.size.height += dh

        // Update snapshot frame to reflect current intent
        self.currentSnapshot = WindowSnapshot(
            pid: snap.pid,
            axWindow: snap.axWindow,
            cgWindowID: snap.cgWindowID,
            appName: snap.appName,
            frame: newFrame,
            bundleID: snap.bundleID
        )

        setWindowFrame(snap.axWindow, cocoaFrame: newFrame)
    }

    // MARK: - Float Heuristics Logic

    func isFloating(wid: CGWindowID, pid: pid_t, frame: CGRect) -> Bool {
        let exceptions = ConfigParser.shared.config.floatExceptions
        let bid = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
        if let bid = bid, exceptions.contains(where: { $0.appId == bid }) { return true }
        if frame.width < 400 || frame.height < 300 { return true }
        return false
    }

    // MARK: - Geometry & Process Helpers

    private func resolveControlPID(for pid: pid_t) -> pid_t {
        var current = pid
        for _ in 0..<5 {
            let app = AXUIElementCreateApplication(current)
            var val: CFTypeRef?
            if AXUIElementCopyAttributeValue(app, kAXRoleAttribute as CFString, &val) == .success { return current }
            var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, current]
            var info = kinfo_proc()
            var size = MemoryLayout<kinfo_proc>.size
            if sysctl(&mib, 4, &info, &size, nil, 0) == 0 {
                let parent = info.kp_eproc.e_ppid
                if parent <= 1 || parent == current { break }
                current = parent
            } else { break }
        }
        return pid
    }

    func axFlipHeight() -> CGFloat {
        return (NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens[0]).frame.height
    }

    private func axFrameToCocoa(_ f: CGRect) -> CGRect {
        let flip = axFlipHeight()
        return CGRect(x: f.origin.x, y: flip - (f.origin.y + f.height), width: f.width, height: f.height)
    }

    private func axFrameOfWindow(_ win: AXUIElement) -> CGRect? {
        var posVal: CFTypeRef?, sizeVal: CFTypeRef?
        var origin = CGPoint.zero, size = CGSize.zero
        if AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posVal) == .success,
           let pv = posVal, AXValueGetValue((pv as! AXValue), .cgPoint, &origin),
           AXUIElementCopyAttributeValue(win, kAXSizeAttribute as CFString, &sizeVal) == .success,
           let sv = sizeVal, AXValueGetValue((sv as! AXValue), .cgSize, &size) {
            return CGRect(origin: origin, size: size)
        }
        return nil
    }

    private func getScreenContaining(_ win: AXUIElement) -> NSScreen? {
        guard let axFrame = axFrameOfWindow(win) else { return NSScreen.main }
        let cocoaFrame = axFrameToCocoa(axFrame)
        let center = CGPoint(x: cocoaFrame.midX, y: cocoaFrame.midY)
        return NSScreen.screens.first { NSMouseInRect(center, $0.frame, false) } ?? NSScreen.main
    }
}

// MARK: - Models

struct WindowSnapshot: Equatable {
    let pid: pid_t
    let axWindow: AXUIElement
    let cgWindowID: CGWindowID
    let appName: String
    let frame: CGRect
    let bundleID: String?

    static func == (lhs: WindowSnapshot, rhs: WindowSnapshot) -> Bool {
        return lhs.cgWindowID == rhs.cgWindowID && lhs.pid == rhs.pid
    }
}

struct WindowCandidate: Identifiable {
    let id: CGWindowID
    let pid: pid_t
    let appName: String
    let title: String
    let frame: CGRect
    let bundleID: String
}
