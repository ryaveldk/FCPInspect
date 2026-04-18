import SwiftUI
import FCPInspectAnalysis

struct FindingsListView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Group {
            if state.findings.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Theme.canvas)
    }

    // MARK: Empty states

    @ViewBuilder private var emptyState: some View {
        if state.sources.isEmpty {
            DropZone()
        } else {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.cyan)
                Text("No findings")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(state.sources.count) source\(state.sources.count == 1 ? "" : "s") scanned · all checks passed.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: List

    private var list: some View {
        List(selection: $state.selectedFindingID) {
            ForEach(state.findings) { finding in
                findingRow(finding)
                    .listRowBackground(
                        state.selectedFindingID == finding.id
                        ? Theme.cyanSoft
                        : Color.clear
                    )
                    .tag(finding.id)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func findingRow(_ finding: Finding) -> some View {
        HStack(alignment: .top, spacing: 10) {
            severityDot(finding.severity)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 3) {
                Text(finding.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(finding.checkID)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(0.5)
                Text(firstLine(of: finding.description))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
    }

    private func severityDot(_ severity: Finding.Severity) -> some View {
        Circle()
            .fill(severity.tint)
            .frame(width: 8, height: 8)
    }

    private func firstLine(of markdown: String) -> String {
        markdown
            .split(whereSeparator: { $0.isNewline })
            .first
            .map(String.init) ?? ""
    }
}

extension Finding.Severity {
    var tint: Color {
        switch self {
        case .info: return Theme.severityInfo
        case .warning: return Theme.severityWarning
        case .error: return Theme.severityError
        }
    }

    var label: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}
