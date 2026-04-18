import Foundation
import FCPInspectAnalysis
import FCPInspectCore

/// Renders a Milestone 1 analysis run as a markdown report. The shape
/// follows the brief's sample output.
struct MarkdownReporter {

    let sourceFiles: [URL]
    let document: FCPXMLDocument
    let checks: [Check]
    let findings: [Finding]

    func render() -> String {
        var out = ""
        out += "# FCPInspect Report\n\n"

        if sourceFiles.count == 1 {
            out += "**File:** \(sourceFiles[0].lastPathComponent)\n"
        } else {
            out += "**Files (\(sourceFiles.count)):**\n"
            for file in sourceFiles {
                out += "- \(file.lastPathComponent)\n"
            }
        }
        out += "**FCPXML Version:** \(document.version.isEmpty ? "unknown" : document.version)\n"
        out += "**Checks run:** \(checks.count)\n"
        out += "**Multicam media objects scanned:** \(document.medias.filter { $0.multicam != nil }.count)\n\n"

        if findings.isEmpty {
            out += "_No findings._ ✅\n"
            return out
        }

        for finding in findings {
            out += "## \(emoji(for: finding.severity)) \(finding.title)\n\n"
            out += finding.description
            if !finding.description.hasSuffix("\n") { out += "\n" }
            if let remediation = finding.suggestedRemediation {
                out += "\n**Suggested remediation:** \(remediation)\n"
            }
            out += "\n"
        }

        return out
    }

    private func emoji(for severity: Finding.Severity) -> String {
        switch severity {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}
