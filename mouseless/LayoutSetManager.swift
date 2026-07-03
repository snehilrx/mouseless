import Foundation
import AppKit

struct LayoutSet: Codable {
    let name: String
    let entries: [LayoutEntry]
}

struct LayoutEntry: Codable {
    let bundleID: String
    let appName: String
    let frame: CGRect
    let workspaceID: String
}

class LayoutSetManager {
    static let shared = LayoutSetManager()

    private let layoutsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Mouseless/layouts.json")

    private init() {
        try? FileManager.default.createDirectory(at: layoutsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    func saveLayout(name: String) {
        Task { @MainActor in
            let candidates = WindowManager.shared.availableCandidates
            let activeWorkspace = WorkspaceManager.shared.activeWorkspaceID

            let entries = candidates.map { cand in
                LayoutEntry(bundleID: cand.bundleID, appName: cand.appName, frame: cand.frame, workspaceID: activeWorkspace)
            }

            let layoutSet = LayoutSet(name: name, entries: entries)
            if let data = try? JSONEncoder().encode(layoutSet) {
                try? data.write(to: layoutsURL)
            }
        }
    }

    func restoreLayout() {
        guard let data = try? Data(contentsOf: layoutsURL),
              let layoutSet = try? JSONDecoder().decode(LayoutSet.self, from: data) else { return }

        Task { @MainActor in
            for entry in layoutSet.entries {
                // Find running app by bundleID
                if NSRunningApplication.runningApplications(withBundleIdentifier: entry.bundleID).first != nil {
                    // Logic to find window and apply frame
                    // WindowManager.shared.setWindowFrame(...)
                }
            }
        }
    }
}
