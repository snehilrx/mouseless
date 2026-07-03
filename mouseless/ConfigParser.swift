import Foundation
import AppKit
import Combine

struct Config: Codable {
    var general: GeneralConfig = .init()
    var gaps: Gaps = .init()
    var workspaces: WorkspaceConfig = .init()
    var rules: [AppRule] = []
    var floatExceptions: [FloatException] = []
    var callbacks: Callbacks = .init()
}

struct GeneralConfig: Codable {
    var startAtLogin: Bool = false
    var defaultWorkspace: String = "1"
}

struct Gaps: Codable {
    var inner: CGFloat = 0
    var outerTop: CGFloat = 0
    var outerBottom: CGFloat = 0
    var outerLeft: CGFloat = 0
    var outerRight: CGFloat = 0
}

struct WorkspaceConfig: Codable {
    var persistent: [String] = ["1", "2", "3", "W", "X", "T"]
}

struct AppRule: Codable {
    var appId: String?
    var appName: String?
    var workspace: String
    var layout: String?
}

struct FloatException: Codable {
    var appId: String?
}

struct Callbacks: Codable {
    var execOnWorkspaceChange: String = ""
}

@MainActor
class ConfigParser: ObservableObject {
    static let shared = ConfigParser()
    @Published var config = Config()

    private let configPath = NSString(string: "~/.mouseless.toml").expandingTildeInPath
    private var stream: FSEventStreamRef?

    private init() {
        loadConfig()
        setupWatcher()
    }

    func loadConfig() {
        print("[Config] Loading configuration...")
        // Note: Basic manual parsing logic if no TOML library is available
        // In a production app, use a proper TOML parser
        self.config = Config() // Placeholder for actual parsed data
    }

    private func setupWatcher() {
        let path = (configPath as NSString).deletingLastPathComponent
        let paths = [path] as CFArray
        var context = FSEventStreamContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)

        let flags = kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
        stream = FSEventStreamCreate(nil, { _, clientCallBackInfo, numEvents, eventPaths, _, _ in
            guard let clientCallBackInfo = clientCallBackInfo else { return }
            let parser = Unmanaged<ConfigParser>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]

            var shouldReload = false
            for i in 0..<numEvents {
                if paths[i].hasSuffix(".mouseless.toml") {
                    shouldReload = true
                    break
                }
            }

            if shouldReload {
                Task { @MainActor in parser.loadConfig() }
            }
        }, &context, paths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 1.0, UInt32(flags))

        if let stream = stream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
            FSEventStreamStart(stream)
        }
    }

    func runWorkspaceCallback(id: String) {
        let cmd = config.callbacks.execOnWorkspaceChange
        if !cmd.isEmpty {
            let script = cmd.replacingOccurrences(of: "$WORKSPACE", with: id)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", script]
            try? process.run()
        }
    }
}
