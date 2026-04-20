import Foundation
import FCPInspectCore

/// Renders an analysis run as a markdown document. Used by the CLI, by
/// the Copy/Save-report actions in the SwiftUI app, and by anything that
/// wants a shareable textual representation of a run.
public struct MarkdownReporter {

    public let sourceFiles: [URL]
    public let document: FCPXMLDocument
    public let checks: [Check]
    public let findings: [Finding]

    public init(
        sourceFiles: [URL],
        document: FCPXMLDocument,
        checks: [Check],
        findings: [Finding]
    ) {
        self.sourceFiles = sourceFiles
        self.document = document
        self.checks = checks
        self.findings = findings
    }

    public func render() -> String {
        var out = ""
        out += "# FCPInspect Report\n\n"

        if sourceFiles.count == 1 {
            out += "**File:** \(sourceFiles[0].lastPathComponent)\n"
        } else if !sourceFiles.isEmpty {
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
            out += "## \(Self.emoji(for: finding.severity)) \(finding.title)\n\n"
            out += finding.description
            if !finding.description.hasSuffix("\n") { out += "\n" }
            if let remediation = finding.suggestedRemediation {
                out += "\n**Suggested remediation:** \(remediation)\n"
            }
            if !finding.location.isEmpty {
                out += "\n**XML locations:**\n"
                for location in finding.location {
                    out += "- `\(location.xpath)`\n"
                }
            }
            out += "\n"
        }

        return out
    }

    private static func emoji(for severity: Finding.Severity) -> String {
        switch severity {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}
