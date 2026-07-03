import SwiftUI
import CoreGraphics

struct WindowPreviewPicker: View {
    @ObservedObject var wm = WindowManager.shared
    @State private var selectionIndex = 0

    var body: some View {
        VStack {
            Text("Switch Window").font(.headline).padding()

            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(Array(wm.availableCandidates.enumerated()), id: \.element.id) { index, cand in
                        VStack {
                            WindowThumbnailView(bundleID: cand.bundleID)
                                .frame(width: 200, height: 120)
                                .border(selectionIndex == index ? Color.blue : Color.clear, width: 4)
                            Text(cand.appName).font(.caption)
                        }
                    }
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct WindowThumbnailView: View {
    let bundleID: String
    @State private var icon: NSImage?

    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
            } else {
                Color.gray.overlay(
                    Image(systemName: "window.rectangle")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                )
            }
        }.onAppear { fetchIcon() }
    }

    private func fetchIcon() {
        if let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path {
            self.icon = NSWorkspace.shared.icon(forFile: path)
        }
    }
}
