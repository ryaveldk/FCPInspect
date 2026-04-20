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
        let ranked = group.sorted(by: Self.nameThenDate)
        let angleCount = ranked[0].multicam?.angles.count ?? 0

        var body = ""
        body += "Found \(group.count) multicam master objects sharing the same angle "
        body += "fingerprint (\(angleCount) angles) but with different UIDs.\n\n"

        body += "**Masters in this group:**\n"
        for media in ranked {
            let hint = Self.nameHint(for: media.name)
            body += "- `\(media.name)`"
            body += " — UID: \(media.uid)"
            if let raw = media.modDateRaw { body += " · modDate: \(raw)" }
            if let hint = hint { body += "  _(\(hint))_" }
            body += "\n"
        }

        body += "\n_Which one is the original vs. a ghost cannot be determined from XML alone. "
        body += "Two clues that can help you decide:_\n"
        body += "- _**Name pattern**: FCP auto-names ghosts with a space-number suffix "
        body += "(`Multicam`, `Multicam 1`, `Multicam 2`…). The unsuffixed name is typically the original._\n"
        body += "- _**modDate**: changes only when a multicam's structure is edited (angle order, "
        body += "format). If you've edited the original since a ghost was born, the original's "
        body += "modDate will be newer — the opposite of what you'd intuit._\n"
        body += "\n_Definitive check: in FCP, pick a timeline instance and press ⇧F (match-frame). "
        body += "The master that opens in the Event browser is the one your timeline references._\n"

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

    /// Orders masters in a neutral, deterministic way for presentation.
    /// Prefers the unsuffixed "base" name first (most likely candidate for
    /// original per FCP's auto-naming), then by modDate ascending, then name.
    private static func nameThenDate(_ a: Media, _ b: Media) -> Bool {
        let aHasSuffix = nameHasGhostSuffix(a.name)
        let bHasSuffix = nameHasGhostSuffix(b.name)
        if aHasSuffix != bHasSuffix { return !aHasSuffix }

        let lhs = a.modDate ?? .distantFuture
        let rhs = b.modDate ?? .distantFuture
        if lhs != rhs { return lhs < rhs }
        return a.name < b.name
    }

    /// Matches FCP's auto-generated ghost naming: a trailing space followed
    /// by digits (e.g. `"Multicam 1"`, `"Multicam 17"`).
    private static func nameHasGhostSuffix(_ name: String) -> Bool {
        let pattern = #" \d+$"#
        return name.range(of: pattern, options: .regularExpression) != nil
    }

    private static func nameHint(for name: String) -> String? {
        if nameHasGhostSuffix(name) {
            return "suffix matches FCP auto-naming → likely ghost"
        }
        return "unsuffixed name → likely original"
    }
}
