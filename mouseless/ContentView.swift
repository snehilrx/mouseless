//
//  ContentView.swift
//  mouseless
//
//  Created by Snehil on 24/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selection: SidebarItem? = .grid

    @State private var trainerVM = TrainerViewModel()
    @FocusState private var isSearchFocused: Bool

    enum SidebarItem: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case trainer = "Trainer"
        var id: String { self.rawValue }

        var icon: String {
            switch self {
            case .grid: return "grid"
            case .trainer: return "graduationcap"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Mouseless")

            VStack {
                Spacer()
                Button(role: .destructive, action: { NSApplication.shared.terminate(nil) }) {
                    Label("Quit Mouseless", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding()
            }
        } detail: {
            ZStack {
                switch selection {
                case .grid:
                    gridView
                case .trainer:
                    trainerView
                case .none:
                    Text("Select an item").foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 750, minHeight: 550)
    }

    // MARK: - Subviews

    private var gridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mouseless Grid")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Keyboard-driven cursor navigation for macOS.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Main Action
                Button(action: { GridController.shared.show() }) {
                    HStack {
                        Image(systemName: "macpro.gen1")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Activate Grid Overlay")
                                .font(.headline)
                            Text("CapsLock to toggle from anywhere")
                                .font(.caption)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.body.bold())
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Status Cards
                HStack(spacing: 16) {
                    StatusCard(title: "Active Monitor", value: "Primary Display", icon: "display")
                    StatusCard(title: "Navigation Mode", value: "2x2 WASD", icon: "squareshape.split.2x2")
                }

                // Shortcuts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Reference")
                        .font(.headline)

                VStack(spacing: 0) {
                        ShortcutRow(keys: "CapsLock", desc: "Toggle Grid Overlay")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "W A S D", desc: "Subdivide / Navigate")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "B", desc: "Undo / Go Back")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "R", desc: "Reset Grid to Full Screen")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "Space", desc: "Left Click / Release Drag")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "X", desc: "Toggle Drag (Hold Down)")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "F / V", desc: "Right / Double Click")
                        Divider().padding(.vertical, 8)
                        ShortcutRow(keys: "H / ?", desc: "Toggle Help Overlay")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                }

            VStack(alignment: .leading, spacing: 12) {
                    Label("Window Management (Snap)", systemImage: "macwindow")
                        .font(.headline)
                    Text("While the Grid is active, hold **Shift** to enter Snap Mode. This allows you to instantly reposition the current window.")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ShortcutRow(keys: "⇧ + W", desc: "Maximize / Fill Screen")
                        ShortcutRow(keys: "⇧ + S", desc: "Center Window")
                        ShortcutRow(keys: "⇧ + A", desc: "Left Half")
                        ShortcutRow(keys: "⇧ + D", desc: "Right Half")
                        ShortcutRow(keys: "⇧ + C", desc: "Auto-Tile All Visible Windows")
                        ShortcutRow(keys: "⇧ + T", desc: "Smart Tile (2 or 4 Windows)")
                        ShortcutRow(keys: "⇧ + Q / E", desc: "Cycle Windows (Prev / Next)")
                        ShortcutRow(keys: "⇧ + Tab", desc: "Cycle Window to Next Monitor")
                        ShortcutRow(keys: "Tab", desc: "Move Grid to Next Monitor")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Workspace Management", systemImage: "rectangle.stack")
                        .font(.headline)
                    Text("Mouseless provides virtual workspaces by moving windows to an off-screen area. This allows you to group windows and switch between them instantly.")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ShortcutRow(keys: "⌥ + ⇧ + [1-9]", desc: "Move active window to Workspace 1-9")
                        ShortcutRow(keys: "⌥ + [1-9]", desc: "Switch to Workspace 1-9")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(8)

                    Text("When you switch workspaces, Mouseless restores the window positions for the target workspace and moves the current ones away.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Selection Guide", systemImage: "cursorarrow.and.square.on.square.dashed")
                        .font(.headline)
                    Text("How to select text in a browser:")
                        .font(.subheadline.bold())

                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Use the grid to position the cursor at the start of the text.")
                        Text("2. Press **'V'** for a double-click to select a word, or **Space** to focus.")
                        Text("3. Use **Shift + Arrow Keys** (system-wide) to expand your selection.")
                        Text("4. Tip: Use **'D'** for a right-click if needed for context menus.")
                    }
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding(24)
        }
    }

    struct StatusCard: View {
        let title: String
        let value: String
        let icon: String
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }

    private var trainerView: some View {
        List {
            if trainerVM.isSessionActive {
                trainerActiveContent
            } else {
                trainerLandingContent
            }
        }
        .listStyle(.inset)
        .navigationTitle("Shortcut Trainer")
    }

    private var trainerActiveContent: some View {
        Group {
            Section {
                HStack(spacing: 20) {
                    ScoreBox(title: "SCORE", value: "\(trainerVM.score)/\(trainerVM.total)", color: .blue)
                    ScoreBox(title: "STREAK", value: "\(trainerVM.streak)", color: .orange, isStreak: true)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if let current = trainerVM.currentShortcut {
                Section {
                    VStack(spacing: 32) {
                        Text(current.category)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                            .foregroundColor(.accentColor)

                        Text(current.description)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Text(trainerVM.userInput.isEmpty ? "Perform the shortcut" : trainerVM.userInput.uppercased())
                                .font(.system(size: 32, weight: .black, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.primary.opacity(0.05))
                                )

                            if let feedback = trainerVM.feedback {
                                Text(feedback)
                                    .font(.headline)
                                    .foregroundColor(trainerVM.isCorrect == true ? .green : .red)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            }

            Section {
                Button(action: { withAnimation { trainerVM.stopSession() } }) {
                    Text("End Practice Session")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding()
            }
            .listRowBackground(Color.clear)
        }
    }

    struct ScoreBox: View {
        let title: String
        let value: String
        let color: Color
        var isStreak: Bool = false

        var body: some View {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(color)
                if isStreak {
                    Text("🔥").font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
        }
    }

    private var trainerLandingContent: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Master your workflow without the mouse.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Start Random Practice") {
                        withAnimation { trainerVM.startSession(category: nil) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.vertical, 5)
            }

            Section("Shortcut Categories") {
                ForEach(ShortcutCategory.allCases, id: \.self) { category in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(category.rawValue).font(.body).fontWeight(.medium)
                            Text("\(shortcutsData.filter { $0.category == category.rawValue }.count) shortcuts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Practice") {
                            withAnimation { trainerVM.startSession(category: category.rawValue) }
                        }
                        .buttonStyle(.bordered)

                        NavigationLink("", destination: CheatSheetView(category: category.rawValue))
                            .opacity(0).frame(width: 0)
                    }
                }
            }
        }
    }
}

// MARK: - Components

struct ShortcutRow: View {
    let keys: String
    let desc: String
    var body: some View {
        HStack {
            Text(desc)
                .font(.body)
            Spacer()
            HStack(spacing: 4) {
                let parts = keys.split(separator: " ").map(String.init)
                ForEach(0..<parts.count, id: \.self) { index in
                    Text(parts[index])
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.1))
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct CheatSheetView: View {
    let category: String
    var body: some View {
        List(shortcutsData.filter { $0.category == category }) { shortcut in
            HStack {
                VStack(alignment: .leading) {
                    Text(shortcut.description).font(.headline)
                    Text(shortcut.command).monospaced().foregroundColor(.accentColor)
                }
            }
        }
        .navigationTitle(category)
    }
}

struct MeshBackgroundView: View {
    var body: some View {
        Color(nsColor: .windowBackgroundColor)
    }
}

// MARK: - Extensions

extension View {
    func onKeyDown(action: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyDownHandler(action: action))
    }
}

struct KeyDownHandler: NSViewRepresentable {
    let action: (NSEvent) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = action
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self], inMemory: true)
}
