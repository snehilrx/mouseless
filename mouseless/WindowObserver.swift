import AppKit
import ApplicationServices

class WindowObserver {
    static let shared = WindowObserver()

    private init() {}

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

        // Match against rules
        let rules = ConfigParser.shared.config.rules
        for rule in rules {
            if rule.appId == app.bundleIdentifier || rule.appName == app.localizedName {
                Task { @MainActor in
                    WorkspaceManager.shared.moveWindowToWorkspace(wid: 0, workspaceID: rule.workspace)
                }
                break
            }
        }
    }
}
