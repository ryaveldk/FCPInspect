import Foundation
import FCPInspectCore

/// Aggregated admin-style summary of one or more parsed FCPXML sources.
/// The UI renders this directly without having to know the underlying
/// FCPXML schema.
public struct DocumentOverview {

    public let sections: [Section]

    public init(sections: [Section]) {
        self.sections = sections
    }

    // MARK: Section model

    public struct Section: Identifiable {
        public let id = UUID()
        public let title: String
        public let subtitle: String?
        public let rows: [Row]
        public let emphasize: Bool

        public init(title: String, subtitle: String? = nil, rows: [Row], emphasize: Bool = false) {
            self.title = title
            self.subtitle = subtitle
            self.rows = rows
            self.emphasize = emphasize
        }
    }

    public struct Row: Identifiable {
        public let id = UUID()
        public let label: String
        public let value: String
        public let isMonospace: Bool

        public init(label: String, value: String, isMonospace: Bool = false) {
            self.label = label
            self.value = value
            self.isMonospace = isMonospace
        }
    }

    // MARK: Construction

    /// Build an overview for a merged set of source documents.
    public static func build(
        from sources: [(url: URL, document: FCPXMLDocument)]
    ) -> DocumentOverview {
        guard !sources.isEmpty else { return DocumentOverview(sections: []) }
        var sections: [Section] = []

        sections.append(filesSection(sources: sources))
        if let librarySection = librarySection(sources: sources) {
            sections.append(librarySection)
        }
        if let contentSection = contentSection(sources: sources) {
            sections.append(contentSection)
        }
        if let formatsSection = formatsSection(sources: sources) {
            sections.append(formatsSection)
        }
        if let environmentSection = environmentSection(sources: sources) {
            sections.append(environmentSection)
        }
        sections.append(statisticsSection(sources: sources))

        return DocumentOverview(sections: sections)
    }

    // MARK: Sections

    private static func filesSection(
        sources: [(url: URL, document: FCPXMLDocument)]
    ) -> Section {
        var rows: [Row] = []
        if sources.count == 1 {
            let src = sources[0]
            rows.append(Row(label: "Fil", value: src.url.lastPathComponent))
            rows.append(Row(label: "Sti", value: src.url.path, isMonospace: true))
            rows.append(Row(label: "FCPXML-version", value: src.document.version.isEmpty ? "ukendt" : src.document.version))
            if let size = fileSize(at: src.url) {
                rows.append(Row(label: "Størrelse", value: byteCountFormatter.string(fromByteCount: size)))
            }
        } else {
            rows.append(Row(label: "Antal kilder", value: "\(sources.count)"))
            let versions = Set(sources.map(\.document.version)).sorted()
            rows.append(Row(label: "FCPXML-version(er)", value: versions.joined(separator: ", ")))
            let totalSize = sources.compactMap { fileSize(at: $0.url) }.reduce(0, +)
            if totalSize > 0 {
                rows.append(Row(label: "Samlet størrelse", value: byteCountFormatter.string(fromByteCount: totalSize)))
            }
            for (idx, src) in sources.enumerated() {
                rows.append(Row(label: "Kilde \(idx + 1)", value: src.url.lastPathComponent))
            }
        }
        return Section(title: "Fil", rows: rows, emphasize: true)
    }

    private static func librarySection(
        sources: [(url: URL, document: FCPXMLDocument)]
    ) -> Section? {
        let libraries = sources.compactMap(\.document.library)
        guard !libraries.isEmpty else { return nil }

        var rows: [Row] = []
        for (idx, lib) in libraries.enumerated() {
            if libraries.count > 1 {
                rows.append(Row(label: "— Bibliotek \(idx + 1) —", value: ""))
            }
            if let path = lib.locationURL?.path {
                rows.append(Row(label: "Sti", value: path, isMonospace: true))
            } else if let loc = lib.location {
                rows.append(Row(label: "Location", value: loc, isMonospace: true))
            }
            if let user = lib.originatingUsername {
                rows.append(Row(label: "Oprindelses-bruger", value: user))
            }
            if lib.events.isEmpty {
                rows.append(Row(label: "Events", value: "ingen"))
            } else {
                rows.append(Row(label: "Events", value: "\(lib.events.count)"))
                for event in lib.events {
                    rows.append(Row(label: "  ↳ \(event.name)", value: "\(event.projects.count) projekt\(event.projects.count == 1 ? "" : "er")"))
                    for project in event.projects {
                        let date = project.modDateRaw ?? "—"
                        rows.append(Row(label: "      · \(project.name)", value: date))
                    }
                }
            }
        }

        return Section(title: "Bibliotek & projekter", rows: rows)
    }

    private static func contentSection(
        sources: [(url: URL, document: FCPXMLDocument)]
    ) -> Section? {
        let allAssets = sources.flatMap(\.document.assets)
        let allMedias = sources.flatMap(\.document.medias)
        let multicams = allMedias.filter { $0.multicam != nil }
        guard !allAssets.isEmpty || !allMedias.isEmpty else { return nil }

        var rows: [Row] = []
        rows.append(Row(label: "Assets (kildeklip)", value: "\(allAssets.count)"))
        let videoAssets = allAssets.filter { $0.hasVideo }.count
        let audioAssets = allAssets.filter { $0.hasAudio }.count
        rows.append(Row(label: "  med video", value: "\(videoAssets)"))
        rows.append(Row(label: "  med audio", value: "\(audioAssets)"))

        rows.append(Row(label: "Media-objekter", value: "\(allMedias.count)"))
        rows.append(Row(label: "  heraf multicams", value: "\(multicams.count)"))

        if !multicams.isEmpty {
            let totalAngles = multicams.reduce(0) { $0 + ($1.multicam?.angles.count ?? 0) }
            rows.append(Row(label: "Multicam angles (samlet)", value: "\(totalAngles)"))
            let avg = Double(totalAngles) / Double(multicams.count)
            rows.append(Row(label: "Angles per multicam (snit)", value: String(format: "%.1f", avg)))
        }

        if let totalDuration = totalAssetSeconds(allAssets) {
            rows.append(Row(label: "Samlet asset-varighed", value: formatDuration(seconds: totalDuration)))
        }

        return Section(title: "Indhold", rows: rows)
    }

    private static func formatsSection(
        sources: [(url: URL, document: FCPXMLDocument)]
    ) -> Section? {
        let allFormats = sources.flatMap(\.document.formats)
        guard !allFormats.isEmpty else { return nil }

        var rows: [Row] = []
        rows.append(Row(label: "Antal formater", value: "\(allFormats.count)"))

        let resolutions = Set(allFormats.compactMap(\.resolution)).sorted()
        if !resolutions.isEmpty {
            rows.append(Row(label: "Opløsninger", value: resolutions.joined(separator: ", ")))
        }
        let colorSpaces = Set(allFormats.compactMap(\.colorSpace)).sorted()
        if !colorSpaces.isEmpty {
            rows.append(Row(label: "Farverum", value: colorSpaces.joined(separator: ", ")))
        }
        let fpsValues = Set(allFormats.compactMap(\.framesPerSecond).map { round($0 * 100) / 100 })
        if !fpsValues.isEmpty {
            let joined = fpsValues.sorted().map { fps -> String in
                let rounded = fps.rounded()
                return rounded == fps ? "\(Int(rounded))" : String(format: "%.2f", fps)
            }.joined(separator: ", ")
            rows.append(Row(label: "Billedhastigheder", value: joined + " fps"))
        }
        for format in allFormats.prefix(8) {
            let summary = [format.resolution, format.framesPerSecond.map { String(format: "%.2f fps", $0) }, format.colorSpace]
                .compactMap { $0 }
                .joined(separator: " · ")
            rows.append(Row(label: "  \(format.name ?? format.id)", value: summary.isEmpty ? format.id : summary))
        }
        if allFormats.count > 8 {
            rows.append(Row(label: "  …", value: "+\(allFormats.count - 8) mere"))
        }

        return Section(title: "Formater", rows: rows)
    }

    private static func environmentSection(
        sources: [(url: URL, document: FCPXMLDocument)]
    ) -> Section? {
        let allAssets = sources.flatMap(\.document.assets)
        guard !allAssets.isEmpty else { return nil }

        var metadataBuckets: [String: Set<String>] = [:]
        for asset in allAssets {
            for entry in asset.metadata {
                metadataBuckets[entry.key, default: []].insert(entry.value)
            }
        }

        guard !metadataBuckets.isEmpty else { return nil }

        var rows: [Row] = []
        let keyLabels: [(String, String)] = [
            ("com.apple.proapps.mio.cameraName", "Kameraer"),
            ("com.apple.proapps.studio.reel", "Reels"),
            ("com.apple.proapps.studio.scene", "Scenes"),
            ("com.apple.proapps.studio.angle", "Angles"),
            ("com.apple.proapps.studio.cameraColorTemperature", "Kamera-farvetemp"),
            ("com.apple.proapps.studio.cameraISO", "Kamera-ISO"),
            ("com.apple.proapps.studio.rawToLogConversion", "RAW→Log"),
            ("com.apple.proapps.spotlight.kMDItemCodecs", "Codecs"),
            ("com.apple.proapps.spotlight.kMDItemProfileName", "Profiler")
        ]

        for (key, label) in keyLabels {
            guard var values = metadataBuckets[key] else { continue }
            values.remove("") // ignore blank
            values.remove(" ")
            guard !values.isEmpty else { continue }
            let sorted = values.sorted()
            let preview: String
            if sorted.count <= 5 {
                preview = sorted.joined(separator: ", ")
            } else {
                preview = sorted.prefix(5).joined(separator: ", ") + " + \(sorted.count - 5) mere"
            }
            rows.append(Row(label: "\(label) (\(sorted.count))", value: preview))
        }

        // Ingest date range — parse the date strings and show earliest/latest.
        if let ingestSet = metadataBuckets["com.apple.proapps.mio.ingestDate"] {
            let parsed = ingestSet.compactMap(parseIngestDate)
            if let earliest = parsed.min(), let latest = parsed.max() {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                df.locale = Locale(identifier: "en_US_POSIX")
                let range: String
                if earliest == latest {
                    range = df.string(from: earliest)
                } else {
                    range = "\(df.string(from: earliest)) — \(df.string(from: latest))"
                }
                rows.append(Row(label: "Ingest-datoer", value: range))
            }
        }

        // Fallback: show any unknown metadata keys that had values.
        let known = Set(keyLabels.map(\.0) + ["com.apple.proapps.mio.ingestDate"])
        let unknownKeys = metadataBuckets.keys.filter { !known.contains($0) && !metadataBuckets[$0, default: []].isEmpty }
        if !unknownKeys.isEmpty {
            let preview = unknownKeys.sorted().prefix(6).joined(separator: ", ")
            rows.append(Row(label: "Øvrige metadata-nøgler", value: preview + (unknownKeys.count > 6 ? " + \(unknownKeys.count - 6) mere" : "")))
        }

        guard !rows.isEmpty else { return nil }
        return Section(title: "Miljø & metadata", rows: rows)
    }

    private static func statisticsSection(
        sources: [(url: URL, document: FCPXMLDocument)]
    ) -> Section {
        let totalMarkers = sources.reduce(0) { $0 + $1.document.markerCount }
        let totalKeywords = sources.reduce(0) { $0 + $1.document.keywordCount }
        var rows: [Row] = [
            Row(label: "Markers", value: "\(totalMarkers)"),
            Row(label: "Keywords", value: "\(totalKeywords)")
        ]
        if sources.count > 1 {
            rows.append(Row(label: "På tværs af", value: "\(sources.count) kilder"))
        }
        return Section(title: "Statistik", rows: rows)
    }

    // MARK: Helpers

    private static func fileSize(at url: URL) -> Int64? {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }

        if isDir.boolValue || url.pathExtension.lowercased() == "fcpxmld" {
            // Walk the bundle directory.
            let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
            var total: Int64 = 0
            while let child = enumerator?.nextObject() as? URL {
                if let size = (try? child.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    total += Int64(size)
                }
            }
            return total
        }

        return (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
    }

    private static let byteCountFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    private static func totalAssetSeconds(_ assets: [Asset]) -> Double? {
        let total = assets.reduce(0.0) { acc, asset in
            guard let d = asset.duration else { return acc }
            return acc + d.doubleValue
        }
        return total > 0 ? total : nil
    }

    private static func formatDuration(seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%dt %02dm %02ds", hours, minutes, secs)
        }
        return String(format: "%dm %02ds", minutes, secs)
    }

    private static func parseIngestDate(_ raw: String) -> Date? {
        let formats = [
            "yyyy-MM-dd HH:mm:ss Z",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            df.dateFormat = format
            if let date = df.date(from: raw) { return date }
        }
        return nil
    }
}
