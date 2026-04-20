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
        let ranked = group.sorted(by: Self.oldestFirst)
        let likelyOriginal = ranked[0]
        let likelyDuplicates = Array(ranked.dropFirst())

        let angleCount = likelyOriginal.multicam?.angles.count ?? 0

        var body = ""
        body += "Found \(group.count) multicam master objects sharing the same angle "
        body += "fingerprint (\(angleCount) angles) but with different UIDs. This typically "
        body += "indicates \"ghost\" multicams created by match-frame operations on "
        body += "out-of-sync timeline references.\n\n"

        body += "**Likely original (oldest modDate):**\n"
        body += "- `\(likelyOriginal.name)` (UID: \(likelyOriginal.uid)"
        if let raw = likelyOriginal.modDateRaw { body += ", modDate: \(raw)" }
        body += ")\n\n"

        body += "**Other masters with same fingerprint (newer — likely ghosts):**\n"
        for candidate in likelyDuplicates {
            body += "- `\(candidate.name)` (UID: \(candidate.uid)"
            if let raw = candidate.modDateRaw { body += ", modDate: \(raw)" }
            body += ")\n"
        }

        body += "\n_Note: a multicam's modDate only changes when its structure is edited (angle "
        body += "order, format, etc.) — not when a timeline clip using it is edited. Ghosts are "
        body += "normally created fresh by FCP during match-frame, so their modDate is newer than "
        body += "the original. Verify by match-framing (Shift+F) a timeline instance to see which "
        body += "master it points at._\n"

        let remediation = """
        Export the project as FCPXML and re-import into a fresh library. The \
        latent snapshot data that causes this duplication is not written to \
        XML and will be discarded on round-trip. Do not drag multicams \
        between libraries — that copies the ghosts along.
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

    /// Orders a duplicate group oldest-first. The oldest `modDate` is the
    /// probable original, because multicam modDates only change on
    /// structural edits, while ghosts are born with a fresh modDate when
    /// FCP creates them during match-frame. Ties break on `name` for
    /// deterministic output.
    private static func oldestFirst(_ a: Media, _ b: Media) -> Bool {
        let lhs = a.modDate ?? .distantFuture
        let rhs = b.modDate ?? .distantFuture
        if lhs != rhs { return lhs < rhs }
        return a.name < b.name
    }
}
