import Foundation
import FCPInspectCore

/// Detects "ghost" multicams — multiple `<media>` objects with distinct
/// UIDs but the same angle fingerprint.
///
/// Background: when a user match-frames to a multicam whose timeline
/// reference has drifted out of sync with the current master, Final Cut
/// Pro silently creates a parallel master (with the same angle layout but
/// a fresh UID). These "ghosts" accumulate invisibly and are not written
/// to FCPXML snapshots, which is why a round-trip re-import fixes them.
///
/// Algorithm:
///   1. Collect every `<media>` that contains a `<multicam>`.
///   2. Fingerprint each multicam as the sorted list of its `angleID`s.
///   3. Group by fingerprint. A group of 2+ with distinct UIDs is a finding.
///   4. The authoritative master is the one with the newest `modDate`;
///      the rest are ghosts. Remediation is an FCPXML round-trip.
public struct MulticamDuplicationCheck: Check {

    public let id = "multicam-duplication"
    public let title = "Multicam Duplication"

    public init() {}

    public func run(on document: FCPXMLDocument) -> [Finding] {
        let multicamMedias = document.medias.filter { $0.multicam != nil }

        let grouped = Dictionary(grouping: multicamMedias) { media in
            media.multicam!.angles.map(\.angleID).sorted()
        }

        var findings: [Finding] = []
        for (fingerprint, group) in grouped {
            guard group.count >= 2 else { continue }
            let uniqueUIDs = Set(group.map(\.uid))
            guard uniqueUIDs.count >= 2 else { continue }
            guard !fingerprint.isEmpty else { continue }

            findings.append(makeFinding(for: group))
        }

        // Stable ordering for deterministic output and tests.
        return findings.sorted { $0.title < $1.title }
    }

    // MARK: Finding construction

    private func makeFinding(for group: [Media]) -> Finding {
        let ranked = group.sorted(by: Self.masterFirst)
        let master = ranked[0]
        let ghosts = Array(ranked.dropFirst())

        let angleCount = master.multicam?.angles.count ?? 0

        var body = ""
        body += "Found \(group.count) multicam master objects sharing the same angle "
        body += "fingerprint (\(angleCount) angles) but with different UIDs. This typically "
        body += "indicates \"ghost\" multicams created by match-frame operations on "
        body += "out-of-sync timeline references.\n\n"

        body += "**Authoritative master:**\n"
        body += "- `\(master.name)` (UID: \(master.uid)"
        if let raw = master.modDateRaw { body += ", modDate: \(raw)" }
        body += ")\n\n"

        body += "**Ghost duplicates:**\n"
        for ghost in ghosts {
            body += "- `\(ghost.name)` (UID: \(ghost.uid)"
            if let raw = ghost.modDateRaw { body += ", modDate: \(raw)" }
            body += ")\n"
        }

        let remediation = """
        Export the project as FCPXML and re-import into a fresh library. The \
        latent snapshot data that causes this duplication is not written to \
        XML and will be discarded on round-trip.
        """

        let locations = group.map(\.location)

        return Finding(
            severity: .warning,
            checkID: id,
            title: "Multicam Duplication Detected",
            description: body,
            location: locations,
            suggestedRemediation: remediation
        )
    }

    /// Orders a duplicate group so that the authoritative master comes
    /// first. Newest `modDate` wins; ties break on `name` for determinism.
    private static func masterFirst(_ a: Media, _ b: Media) -> Bool {
        let lhs = a.modDate ?? .distantPast
        let rhs = b.modDate ?? .distantPast
        if lhs != rhs { return lhs > rhs }
        return a.name < b.name
    }
}
