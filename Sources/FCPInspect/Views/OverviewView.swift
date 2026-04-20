import SwiftUI
import FCPInspectAnalysis

struct OverviewView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Group {
            if state.isEmpty {
                DropZone()
            } else {
                content
            }
        }
        .background(Theme.canvas)
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                summaryCards
                ForEach(state.overview.sections) { section in
                    sectionView(section)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Summary cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            card(title: "Kilder", value: "\(state.sources.count)", tint: Theme.cyan)
            card(
                title: "Multicams",
                value: "\(totalMulticams)",
                tint: Theme.cyan
            )
            card(
                title: "Assets",
                value: "\(totalAssets)",
                tint: Theme.cyan
            )
            card(
                title: "Findings",
                value: "\(state.findings.count)",
                tint: state.findings.isEmpty ? Theme.cyanMuted : Theme.severityWarning
            )
        }
    }

    private func card(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
        )
    }

    // MARK: Sections

    private func sectionView(_ section: DocumentOverview.Section) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(section.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(section.emphasize ? Theme.cyan : Theme.textPrimary)
                if let subtitle = section.subtitle {
                    Text("·")
                        .foregroundStyle(Theme.textTertiary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().background(Theme.stroke)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { idx, row in
                    rowView(row)
                        .background(idx % 2 == 0 ? Color.clear : Theme.surfaceElevated.opacity(0.35))
                }
            }
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(section.emphasize ? Theme.cyan.opacity(0.35) : Theme.stroke,
                                lineWidth: 1)
                )
        )
    }

    private func rowView(_ row: DocumentOverview.Row) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(row.label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 200, alignment: .leading)
            Text(row.value)
                .font(row.isMonospace
                      ? .system(size: 12, design: .monospaced)
                      : .system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: Derived

    private var totalMulticams: Int {
        state.sources.reduce(0) { acc, src in
            acc + src.document.medias.filter { $0.multicam != nil }.count
        }
    }

    private var totalAssets: Int {
        state.sources.reduce(0) { $0 + $1.document.assets.count }
    }
}
