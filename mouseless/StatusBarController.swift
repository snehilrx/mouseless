import AppKit

class StatusBarController {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem!

    private init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "[1]"
        setupMenu()
    }

    func updateWorkspaceLabel(name: String) {
        statusItem.button?.title = "[\(name)]"
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Switch Workspace", action: nil, keyEquivalent: ""))
        statusItem.menu = menu
    }
}
