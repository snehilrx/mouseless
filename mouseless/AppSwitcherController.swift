import Cocoa
import Combine
import SwiftUI

struct AppCandidate: Identifiable, Hashable {
    let id = UUID()
    let pid: pid_t
    let name: String
    let icon: NSImage
    let bundleID: String
}

@MainActor
class AppSwitcherController: NSObject, ObservableObject {
    static let shared = AppSwitcherController()

    @Published var apps: [AppCandidate] = []
    @Published var searchText: String = "" {
        didSet { selectedIndex = 0 }
    }
    @Published var selectedIndex: Int = 0
    @Published var isSearching: Bool = false

    private var window: OverlayWindow?
    private var eventMonitor: Any?

    var isVisible: Bool { window?.isVisible ?? false }

    override private init() {
        super.init()
    }

    func show() {
        updateApps()
        searchText = ""
        isSearching = false
        selectedIndex = apps.count > 1 ? 1 : 0

        let screens = NSScreen.screens
        let currentScreen = screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? screens[0]
        let screenRect = currentScreen.frame
        let newRect = NSRect(x: screenRect.midX - 400, y: screenRect.midY - 300, width: 800, height: 600)

        if window == nil {
            window = OverlayWindow(contentRect: newRect, interactive: true)
            window?.contentView = NSHostingView(rootView: AppSwitcherView())
            window?.level = .popUpMenu
        } else {
            window?.setFrame(newRect, display: true)
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if eventMonitor == nil {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                return self.handleEvent(event) ? nil : event
            }
        }
    }

    func hide() {
        window?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func updateApps() {
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowList = (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]) ?? []

        var validPIDs = Set<pid_t>()
        for window in windowList {
            if let pid = window[kCGWindowOwnerPID as String] as? pid_t,
               let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
               let alpha = window[kCGWindowAlpha as String] as? Double, alpha > 0 {
                validPIDs.insert(pid)
            }
        }

        let activeApps = runningApps.filter { validPIDs.contains($0.processIdentifier) }

        self.apps = activeApps.sorted(by: { a, b in
            if a.isActive { return true }
            if b.isActive { return false }
            return (a.localizedName ?? "") < (b.localizedName ?? "")
        }).compactMap { app in
            guard let name = app.localizedName, let bundleID = app.bundleIdentifier else { return nil }
            return AppCandidate(pid: app.processIdentifier, name: name, icon: app.icon ?? NSImage(), bundleID: bundleID)
        }
    }

    func terminateSelected() {
        let fApps = filteredApps()
        if fApps.indices.contains(selectedIndex) {
            let app = fApps[selectedIndex]
            if let runningApp = NSRunningApplication(processIdentifier: app.pid) {
                runningApp.terminate()
                self.apps.removeAll { $0.id == app.id }
                if self.selectedIndex >= self.filteredApps().count {
                    self.selectedIndex = max(0, self.filteredApps().count - 1)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.updateApps() }
            }
        }
    }

    func filteredApps() -> [AppCandidate] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func activateSelected() {
        let fApps = filteredApps()
        if fApps.indices.contains(selectedIndex) {
            NSRunningApplication(processIdentifier: fApps[selectedIndex].pid)?.activate(options: .activateIgnoringOtherApps)
        }
        hide()
    }

    private func handleEvent(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 { hide(); return true }
        if event.modifierFlags.contains(.command) && event.keyCode == 3 { isSearching = true; return true }

        let fApps = filteredApps()
        let count = fApps.count
        guard count > 0 else { return false }

        if isSearching {
            if event.keyCode == 36 { activateSelected(); return true }
            return false
        } else {
            switch event.keyCode {
            case 36, 49: activateSelected(); return true
            case 7: terminateSelected(); return true
            case 44: isSearching = true; return true
            case 13, 126: if selectedIndex >= 5 { selectedIndex -= 5 }; return true
            case 1, 125: if selectedIndex + 5 < count { selectedIndex += 5 }; return true
            case 0, 123: if selectedIndex > 0 { selectedIndex -= 1 }; return true
            case 2, 124: if selectedIndex < count - 1 { selectedIndex += 1 }; return true
            case 18...28: // 1-9
                let mapping: [UInt16: Int] = [18:0, 19:1, 20:2, 21:3, 23:4, 22:5, 26:6, 28:7, 25:8]
                if let idx = mapping[event.keyCode], idx < count { selectedIndex = idx; activateSelected(); return true }
                return false
            default: return false
            }
        }
    }
}
