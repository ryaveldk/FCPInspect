import SwiftUI
import UniformTypeIdentifiers

/// Empty-state drop zone shown in the centre pane when no files are loaded.
/// Accepts file URLs from Finder. The drop handler lives on the root view
/// so that dropping works from any pane once the app has content.
struct DropZone: View {
    @EnvironmentObject var state: AppState
    var onRequestHelp: () -> Void = {}

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.cyan)
            Text("Træk FCPXML ind her")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(".fcpxml-filer, .fcpxmld-bundles eller hele mapper")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 10) {
                Button {
                    state.presentOpenPanel()
                } label: {
                    Text("Åbn…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.canvas)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.cyan))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("o")

                Button {
                    onRequestHelp()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                        Text("Sådan gør du")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.cyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(
                        Capsule().stroke(Theme.cyan.opacity(0.55), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .padding(24)
        )
    }
}

/// Attaches a file-URL drop handler that forwards any dropped items to
/// `AppState`. Apply to the outermost view so a drop anywhere in the
/// window is accepted.
struct FileDropModifier: ViewModifier {
    @EnvironmentObject var state: AppState
    @State private var isTargeted = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if isTargeted {
                    Rectangle()
                        .strokeBorder(Theme.cyan, lineWidth: 3)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                loadURLs(from: providers)
                return true
            }
    }

    private func loadURLs(from providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var urls: [URL] = []

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { urls.append(url) }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            state.add(urls: urls)
        }
    }
}

extension View {
    func acceptsFCPXMLDrops() -> some View { modifier(FileDropModifier()) }
}
