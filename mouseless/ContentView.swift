//
//  ContentView.swift
//  mouseless
//
//  Created by Snehil on 24/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarItem? = .grid

    enum SidebarItem: String, CaseIterable, Identifiable {
        case grid = "Grid"
        var id: String { self.rawValue }

        var icon: String {
            switch self {
            case .grid: return "grid"
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

struct MeshBackgroundView: View {
    var body: some View {
        Color(nsColor: .windowBackgroundColor)
    }
}

#Preview {
    ContentView()
}
