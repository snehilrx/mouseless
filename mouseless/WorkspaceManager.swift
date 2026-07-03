import Foundation
import AppKit
import Combine
@preconcurrency import ApplicationServices

struct Workspace: Identifiable, Codable {
    let id: String
    let name: String
    var windowIDs: [CGWindowID] = []
}

@MainActor
class WorkspaceManager: ObservableObject {
    static let shared = WorkspaceManager()

    @Published var workspaces: [Workspace] = []
    @Published var activeWorkspaceID: String = "1"

    // Store the last known on-screen frame for every window we manage
    private var windowFrames: [CGWindowID: CGRect] = [:]
    private let offscreenPoint = CGPoint(x: -10000, y: -10000)

    private init() {
        loadWorkspaces()
    }

    func switchTo(id: String) {
        guard id != activeWorkspaceID, workspaces.contains(where: { $0.id == id }) else { return }

        print("[Workspaces] 🔄 Switching to Workspace \(id)")
        let currentWSID = activeWorkspaceID
        activeWorkspaceID = id

        let windowsToHide = workspaces.first(where: { $0.id == currentWSID })?.windowIDs ?? []
        let windowsToShow = workspaces.first(where: { $0.id == id })?.windowIDs ?? []

        var hideHandles: [AXUIElement] = []
        for wid in windowsToHide {
            if let win = WindowManager.shared.resolveAXElement(for: wid) {
                hideHandles.append(win)
            }
        }

        var showHandles: [AXUIElement] = []
        for wid in windowsToShow {
            if let win = WindowManager.shared.resolveAXElement(for: wid) {
                showHandles.append(win)
            }
        }

        saveState()
        StatusBarController.shared.updateWorkspaceLabel(name: id)

        Task {
            // Un-minimize target windows FIRST
            for win in showHandles {
                AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, false as CFTypeRef)
            }

            // Minimize old windows
            for win in hideHandles {
                AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, true as CFTypeRef)
            }

            ConfigParser.shared.runWorkspaceCallback(id: id)
        }
    }

    func moveWindowToWorkspace(wid: CGWindowID, workspaceID: String) {
        for i in 0..<workspaces.count {
            workspaces[i].windowIDs.removeAll { $0 == wid }
            if workspaces[i].id == workspaceID {
                workspaces[i].windowIDs.append(wid)
            }
        }

        if workspaceID != activeWorkspaceID {
            // Minimize it immediately
            if let win = WindowManager.shared.resolveAXElement(for: wid) {
                WindowManager.shared.axQueue.async {
                    AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, true as CFTypeRef)
                }
            }
        }
        saveState()
    }

    private func saveState() {
        if let encoded = try? JSONEncoder().encode(workspaces) {
            UserDefaults.standard.set(encoded, forKey: "mouseless_workspaces")
        }
    }

    private func loadWorkspaces() {
        if let data = UserDefaults.standard.data(forKey: "mouseless_workspaces"),
           let decoded = try? JSONDecoder().decode([Workspace].self, from: data) {
            self.workspaces = decoded
        } else {
            self.workspaces = ["1", "2", "3", "W", "X", "T"].map { Workspace(id: $0, name: $0) }
        }
    }
}
