import AppKit
import ApplicationServices

// MARK: - FocusRecord

struct FocusRecord {
    let date: Date
    let pid: pid_t
    let bundleID: String?
    let appName: String?
    let axWindow: AXUIElement
}

// MARK: - FocusHistoryManager
//
// Tracks the last focused non-Mouseless window using two mechanisms:
//   1. NSWorkspace.didActivateApplicationNotification (app-level)
//   2. A lightweight 0.25s poll to keep the record fresh
//
// AXObserver is NOT used as primary mechanism because it requires
// the app to be in the observer's run loop, which adds complexity
// and has reliability issues during app startup.

class FocusHistoryManager {
    static let shared = FocusHistoryManager()

    private(set) var lastRecord: FocusRecord?
    private var pollTimer: Timer?
    private var observers: [pid_t: AXObserver] = [:]
    private let selfPID = ProcessInfo.processInfo.processIdentifier

    private init() {}

    // MARK: - Lifecycle

    func start() {
        print("[FocusHistory] 🚀 Starting")

        // Watch app activations
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // Attach AXObservers to all running apps (belt-and-suspenders)
        for app in NSWorkspace.shared.runningApplications {
            tryAttachAXObserver(to: app)
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        // Poll as backup — catches cases where AX notifications don't fire
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)

        // Snapshot the currently focused non-Mouseless app immediately
        poll()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        observers.removeAll()
    }

    // MARK: - AXObserver

    private func tryAttachAXObserver(to app: NSRunningApplication) {
        let pid = app.processIdentifier
        guard pid != selfPID,
              isTrackable(app),
              observers[pid] == nil
        else { return }

        var obs: AXObserver?
        guard AXObserverCreate(pid, { _, element, _, refcon in
            guard let refcon else { return }
            let mgr = Unmanaged<FocusHistoryManager>.fromOpaque(refcon).takeUnretainedValue()
            var p: pid_t = 0
            AXUIElementGetPid(element, &p)
            DispatchQueue.main.async { mgr.pollPID(p) }
        }, &obs) == .success, let obs else { return }

        let axApp = AXUIElementCreateApplication(pid)
        let selfRef = Unmanaged.passUnretained(self).toOpaque()
        AXObserverAddNotification(obs, axApp, kAXFocusedWindowChangedNotification as CFString, selfRef)
        AXObserverAddNotification(obs, axApp, kAXApplicationActivatedNotification as CFString, selfRef)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(obs), .defaultMode)
        observers[pid] = obs
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.tryAttachAXObserver(to: app)
        }
    }

    // MARK: - Poll / Snapshot

    /// Called by the timer — snapshots the current frontmost non-Mouseless app.
    private func poll() {
        // First preference: system AX focused app (most accurate)
        let sysWide = AXUIElementCreateSystemWide()
        var appRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(sysWide, kAXFocusedApplicationAttribute as CFString, &appRef) == .success,
           let axApp = appRef.map({ $0 as! AXUIElement }) {
            var pid: pid_t = 0
            AXUIElementGetPid(axApp, &pid)
            if pid != selfPID, let app = NSRunningApplication(processIdentifier: pid), isTrackable(app) {
                if let win = queryWindow(pid: pid) {
                    store(win: win, app: app)
                    return
                }
            }
        }

        // Second preference: NSWorkspace frontmostApplication
        if let front = NSWorkspace.shared.frontmostApplication,
           front.processIdentifier != selfPID,
           isTrackable(front) {
            if let win = queryWindow(pid: front.processIdentifier) {
                store(win: win, app: front)
            }
        }
    }

    /// Snapshot a specific PID — called by AXObserver callback.
    func pollPID(_ pid: pid_t) {
        guard pid != selfPID,
              let app = NSRunningApplication(processIdentifier: pid),
              isTrackable(app),
              let win = queryWindow(pid: pid)
        else { return }
        store(win: win, app: app)
    }

    @objc private func appActivated(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.processIdentifier != selfPID,
              isTrackable(app)
        else { return }

        // Give the app a tiny moment to update its focused window attribute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            if let win = self.queryWindow(pid: app.processIdentifier) {
                self.store(win: win, app: app)
            }
        }
    }

    private func store(win: AXUIElement, app: NSRunningApplication) {
        let isNewApp = lastRecord?.pid != app.processIdentifier
        lastRecord = FocusRecord(
            date: Date(),
            pid: app.processIdentifier,
            bundleID: app.bundleIdentifier,
            appName: app.localizedName,
            axWindow: win
        )
        if isNewApp {
            print("[FocusHistory] 🎯 Now tracking: \(app.localizedName ?? "?") (PID:\(app.processIdentifier))")
        }
    }

    // MARK: - AX Query

    /// Returns the best AX window for a given PID.
    func queryWindow(pid: pid_t) -> AXUIElement? {
        let axApp = AXUIElementCreateApplication(pid)
        var val: CFTypeRef?

        // 1. Focused window
        if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &val) == .success,
           let v = val, CFGetTypeID(v) == AXUIElementGetTypeID() {
            return (v as! AXUIElement)
        }
        // 2. Main window
        if AXUIElementCopyAttributeValue(axApp, kAXMainWindowAttribute as CFString, &val) == .success,
           let v = val, CFGetTypeID(v) == AXUIElementGetTypeID() {
            return (v as! AXUIElement)
        }
        // 3. First visible window from window list
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &val) == .success,
           let arr = val as? [AXUIElement] {
            for w in arr {
                var minRef: CFTypeRef?
                let isMin = AXUIElementCopyAttributeValue(w, kAXMinimizedAttribute as CFString, &minRef) == .success
                    && (minRef as? Bool) == true
                if !isMin { return w }
            }
            if let first = arr.first { return first }
        }
        return nil
    }

    // MARK: - Filter

    private func isTrackable(_ app: NSRunningApplication) -> Bool {
        app.activationPolicy == .regular || app.bundleIdentifier == "com.apple.finder"
    }
}
