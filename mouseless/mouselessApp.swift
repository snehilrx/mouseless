import SwiftUI
import SwiftData

@main
struct mouselessApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        checkAccessibilityPermissions()

        // Warm up shared instances
        _ = ConfigParser.shared
        _ = WorkspaceManager.shared
        _ = ModeManager.shared
        _ = StatusBarController.shared
        _ = GridController.shared

        WindowObserver.shared.start()
        ClickEngine.shared.install()
        FocusHistoryManager.shared.start()

        // Hide dock icon and run as accessory
        DispatchQueue.main.async {
            NSApp?.setActivationPolicy(.accessory)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .modelContainer(sharedModelContainer)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                Text("[\(WorkspaceManager.shared.activeWorkspaceID)]")
            }
        }
        .menuBarExtraStyle(.window)
    }

    func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}
