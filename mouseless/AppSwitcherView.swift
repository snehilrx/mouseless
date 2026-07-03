import SwiftUI
import AppKit

struct AppSwitcherView: View {
    @ObservedObject var controller = AppSwitcherController.shared
    @FocusState private var isSearchFocused: Bool

    let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 16)
    ]

    var body: some View {
        VStack {
            if controller.isSearching {
                TextField("Search Apps...", text: $controller.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 24))
                    .padding()
                    .focused($isSearchFocused)
                    .onAppear { isSearchFocused = true }
            } else {
                Text("App Switcher (Press '/' to search, WASD to navigate, 'X' to close, 1-9 to open)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(controller.filteredApps().enumerated()), id: \.element.id) { index, app in
                        AppTile(index: index, app: app, isSelected: controller.selectedIndex == index)
                            .onTapGesture {
                                controller.selectedIndex = index
                                controller.activateSelected()
                            }
                    }
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
        .background(VisualEffectView().ignoresSafeArea())
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct AppTile: View {
    let index: Int
    let app: AppCandidate
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                Image(nsImage: app.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                if index < 9 {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .offset(x: -8, y: -8)
                }
            }

            Text(app.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
