import SwiftUI
import FCPInspectAnalysis

struct FindingDetailView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Group {
            if let finding = state.selectedFinding {
                detail(for: finding)
            } else {
                placeholder
            }
        }
        .background(Theme.canvas)
    }

    // MARK: Placeholder

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textTertiary)
            Text(state.findings.isEmpty ? "Load an FCPXML to begin" : "Select a finding")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Detail

    private func detail(for finding: Finding) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(finding)
                body(finding)
                if let remediation = finding.suggestedRemediation {
                    remediationBlock(remediation)
                }
                locationsBlock(finding)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func header(_ finding: Finding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(finding.severity.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.canvas)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(finding.severity.tint))
                Text(finding.checkID)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(finding.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func body(_ finding: Finding) -> some View {
        MarkdownText(finding.description)
            .font(.system(size: 13))
            .foregroundStyle(Theme.textPrimary)
            .lineSpacing(4)
    }

    private func remediationBlock(_ remediation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Suggested remediation", systemImage: "wrench.and.screwdriver.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.cyan)
            Text(remediation)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cyanSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.cyan.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func locationsBlock(_ finding: Finding) -> some View {
        Group {
            if !finding.location.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("XML LOCATIONS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textTertiary)
                    ForEach(Array(finding.location.enumerated()), id: \.offset) { _, loc in
                        Text(loc.xpath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}

// MARK: - Markdown rendering

/// Very light markdown rendering sufficient for the finding bodies the
/// engine produces (paragraphs, **bold**, `code`, bullet lists). Uses
/// `AttributedString(markdown:)` for inline formatting on a per-line
/// basis so that line breaks are preserved; the default markdown
/// initialiser collapses them.
struct MarkdownText: View {
    let source: String

    init(_ source: String) { self.source = source }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                if para.isBullet {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•").foregroundStyle(Theme.cyan)
                        Text(para.attributed)
                    }
                } else {
                    Text(para.attributed)
                }
            }
        }
    }

    private struct Paragraph {
        let attributed: AttributedString
        let isBullet: Bool
    }

    private var paragraphs: [Paragraph] {
        source.split(separator: "\n", omittingEmptySubsequences: false).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let isBullet = trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
            let content = isBullet ? String(trimmed.dropFirst(2)) : trimmed
            let attr = (try? AttributedString(markdown: content)) ?? AttributedString(content)
            return Paragraph(attributed: attr, isBullet: isBullet)
        }
    }
}
