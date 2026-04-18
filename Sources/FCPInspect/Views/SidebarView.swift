import SwiftUI
import FCPInspectAnalysis

struct SidebarView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header(title: "SOURCES", action: openPanelAction)
            sourcesList
            Divider().background(Theme.stroke).padding(.vertical, 8)
            header(title: "CHECKS", action: nil)
            checksList
            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .background(Theme.surface)
    }

    // MARK: Sections

    private func header(title: String, action: (() -> Void)?) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if let action {
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.cyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var sourcesList: some View {
        Group {
            if state.sources.isEmpty {
                Text("No files loaded.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            } else {
                ForEach(state.sources) { source in
                    sourceRow(source)
                }
            }
        }
    }

    private func sourceRow(_ source: LoadedSource) -> some View {
        HStack(spacing: 8) {
            Image(systemName: source.url.pathExtension.lowercased() == "fcpxmld"
                  ? "shippingbox.fill" : "doc.text.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.cyanMuted)
            Text(source.displayName)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Button {
                state.remove(source)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Remove from analysis")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var checksList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(state.engine.checks, id: \.id) { check in
                checkRow(check)
            }
        }
    }

    private func checkRow(_ check: Check) -> some View {
        let matchCount = state.findings.filter { $0.checkID == check.id }.count
        return HStack(spacing: 8) {
            Circle()
                .fill(matchCount > 0 ? Theme.severityWarning : Theme.stroke)
                .frame(width: 6, height: 6)
            Text(check.title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            if matchCount > 0 {
                Text("\(matchCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.canvas)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Theme.severityWarning))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func openPanelAction() { state.presentOpenPanel() }
}
