import Foundation

/// DOM-based parser for the subset of FCPXML 1.14 that Milestone 1 needs.
///
/// Library FCPXML exports are rarely larger than a few megabytes, so the
/// readability and random-access benefits of `XMLDocument` outweigh the
/// memory cost versus a SAX parser. If that changes in a later milestone,
/// the public API here (`parse(data:)`, `parse(path:)`) is stable enough
/// that the implementation can be swapped without touching callers.
public final class FCPXMLParser {

    // MARK: Init

    public init() {}

    // MARK: Public entry points

    /// Parses an FCPXML file from a file system path. Accepts either a
    /// bare `.fcpxml` file or an `.fcpxmld` bundle directory; in the
    /// latter case `Info.fcpxml` is read from inside the bundle.
    public func parse(path: URL) throws -> FCPXMLDocument {
        let resolved = Self.resolveDocumentURL(path)
        let data: Data
        do {
            data = try Data(contentsOf: resolved)
        } catch {
            if path.pathExtension.lowercased() == "fcpxmld" {
                throw ParseError.missingInfoFile(bundle: path.path)
            }
            throw ParseError.unreadableFile(
                path: resolved.path,
                underlying: error.localizedDescription
            )
        }
        return try parse(data: data)
    }

    /// Parses an in-memory FCPXML byte blob.
    public func parse(data: Data) throws -> FCPXMLDocument {
        let doc: XMLDocument
        do {
            doc = try XMLDocument(data: data, options: [])
        } catch {
            throw ParseError.malformedXML(message: error.localizedDescription)
        }
        guard let root = doc.rootElement() else {
            throw ParseError.missingRoot
        }
        guard root.name == "fcpxml" else {
            throw ParseError.wrongRoot(name: root.name ?? "?")
        }

        let version = root.attribute(forName: "version")?.stringValue ?? ""

        // Resources
        let resourcesElement = root.elements(forName: "resources").first
        let mediaElements = resourcesElement?.elements(forName: "media") ?? []
        let assetElements = resourcesElement?.elements(forName: "asset") ?? []
        let formatElements = resourcesElement?.elements(forName: "format") ?? []

        let medias = try mediaElements.enumerated().map { idx, element in
            try parseMedia(
                element,
                xpath: "/fcpxml/resources/media[\(idx + 1)]"
            )
        }
        let assets = assetElements.enumerated().map { idx, element in
            parseAsset(
                element,
                xpath: "/fcpxml/resources/asset[\(idx + 1)]"
            )
        }
        let formats = formatElements.enumerated().map { idx, element in
            parseFormat(
                element,
                xpath: "/fcpxml/resources/format[\(idx + 1)]"
            )
        }

        // Library / events / projects
        let library: Library? = root.elements(forName: "library").first.map { libraryElement in
            let location = libraryElement.attribute(forName: "location")?.stringValue
            let events = libraryElement.elements(forName: "event").enumerated().map { idx, element in
                parseEvent(element, xpath: "/fcpxml/library/event[\(idx + 1)]")
            }
            return Library(location: location, events: events)
        }

        // Cheap aggregate counts via XPath descendant scan.
        let markerCount = (try? root.nodes(forXPath: ".//marker").count) ?? 0
        let keywordCount = (try? root.nodes(forXPath: ".//keyword").count) ?? 0

        return FCPXMLDocument(
            version: version,
            library: library,
            assets: assets,
            formats: formats,
            medias: medias,
            markerCount: markerCount,
            keywordCount: keywordCount
        )
    }

    // MARK: URL resolution

    /// Maps a user-supplied path to the actual XML file. Bundle inputs are
    /// unwrapped to `Info.fcpxml`; plain files pass through.
    public static func resolveDocumentURL(_ input: URL) -> URL {
        if input.pathExtension.lowercased() == "fcpxmld" {
            return input.appendingPathComponent("Info.fcpxml")
        }
        return input
    }

    // MARK: Element parsers

    private func parseMedia(_ element: XMLElement, xpath: String) throws -> Media {
        let attrs = attributeDictionary(element)
        guard let id = attrs["id"] else {
            throw ParseError.missingAttribute(element: "media", attribute: "id", xpath: xpath)
        }
        guard let uid = attrs["uid"] else {
            throw ParseError.missingAttribute(element: "media", attribute: "uid", xpath: xpath)
        }
        let name = attrs["name"] ?? ""
        let modDateRaw = attrs["modDate"]
        let modDate = modDateRaw.flatMap(Self.parseModDate)

        let multicamElement = element.elements(forName: "multicam").first
        let multicam = try multicamElement.map {
            try parseMulticam($0, xpath: xpath + "/multicam")
        }

        return Media(
            id: id,
            name: name,
            uid: uid,
            modDateRaw: modDateRaw,
            modDate: modDate,
            multicam: multicam,
            location: XMLLocation(xpath: xpath),
            rawAttributes: attrs
        )
    }

    private func parseMulticam(_ element: XMLElement, xpath: String) throws -> Multicam {
        let attrs = attributeDictionary(element)
        let tcStart = try attrs["tcStart"].map { try Rational.parse($0) }
        let angleElements = element.elements(forName: "mc-angle")
        let angles = try angleElements.enumerated().map { idx, el in
            try parseMCAngle(el, xpath: xpath + "/mc-angle[\(idx + 1)]")
        }
        return Multicam(
            format: attrs["format"],
            tcStart: tcStart,
            tcFormat: attrs["tcFormat"],
            angles: angles,
            location: XMLLocation(xpath: xpath)
        )
    }

    private func parseMCAngle(_ element: XMLElement, xpath: String) throws -> MCAngle {
        let attrs = attributeDictionary(element)
        guard let angleID = attrs["angleID"] else {
            throw ParseError.missingAttribute(element: "mc-angle", attribute: "angleID", xpath: xpath)
        }
        let name = attrs["name"] ?? ""
        let clipElements = element.elements(forName: "asset-clip")
        let clips = try clipElements.enumerated().map { idx, el in
            try parseAssetClip(el, xpath: xpath + "/asset-clip[\(idx + 1)]")
        }
        return MCAngle(
            name: name,
            angleID: angleID,
            assetClips: clips,
            location: XMLLocation(xpath: xpath)
        )
    }

    private func parseAssetClip(_ element: XMLElement, xpath: String) throws -> AssetClip {
        let attrs = attributeDictionary(element)
        guard let ref = attrs["ref"] else {
            throw ParseError.missingAttribute(element: "asset-clip", attribute: "ref", xpath: xpath)
        }
        let offset = try attrs["offset"].map { try Rational.parse($0) }
        let start = try attrs["start"].map { try Rational.parse($0) }
        let duration = try attrs["duration"].map { try Rational.parse($0) }
        return AssetClip(
            ref: ref,
            offset: offset,
            name: attrs["name"],
            start: start,
            duration: duration,
            tcFormat: attrs["tcFormat"],
            audioRole: attrs["audioRole"],
            location: XMLLocation(xpath: xpath)
        )
    }

    // MARK: Asset / Format

    private func parseAsset(_ element: XMLElement, xpath: String) -> Asset {
        let attrs = attributeDictionary(element)
        return Asset(
            id: attrs["id"] ?? "",
            name: attrs["name"] ?? "",
            uid: attrs["uid"],
            src: attrs["src"],
            start: attrs["start"].flatMap { try? Rational.parse($0) },
            duration: attrs["duration"].flatMap { try? Rational.parse($0) },
            hasVideo: attrs["hasVideo"] == "1",
            hasAudio: attrs["hasAudio"] == "1",
            format: attrs["format"],
            videoSources: attrs["videoSources"].flatMap(Int.init),
            audioSources: attrs["audioSources"].flatMap(Int.init),
            audioChannels: attrs["audioChannels"].flatMap(Int.init),
            audioRate: attrs["audioRate"].flatMap(Int.init),
            metadata: metadataEntries(in: element),
            location: XMLLocation(xpath: xpath)
        )
    }

    private func parseFormat(_ element: XMLElement, xpath: String) -> Format {
        let attrs = attributeDictionary(element)
        return Format(
            id: attrs["id"] ?? "",
            name: attrs["name"],
            frameDuration: attrs["frameDuration"].flatMap { try? Rational.parse($0) },
            width: attrs["width"].flatMap(Int.init),
            height: attrs["height"].flatMap(Int.init),
            colorSpace: attrs["colorSpace"],
            location: XMLLocation(xpath: xpath)
        )
    }

    // MARK: Library / Event / Project

    private func parseEvent(_ element: XMLElement, xpath: String) -> Event {
        let attrs = attributeDictionary(element)
        let projects = element.elements(forName: "project").enumerated().map { idx, el in
            parseProject(el, xpath: xpath + "/project[\(idx + 1)]")
        }
        return Event(
            name: attrs["name"] ?? "",
            uid: attrs["uid"],
            projects: projects
        )
    }

    private func parseProject(_ element: XMLElement, xpath: String) -> Project {
        let attrs = attributeDictionary(element)
        let sequenceElement = element.elements(forName: "sequence").first
        let seqAttrs = sequenceElement.map(attributeDictionary) ?? [:]
        return Project(
            name: attrs["name"] ?? "",
            id: attrs["id"],
            uid: attrs["uid"],
            modDateRaw: attrs["modDate"],
            modDate: attrs["modDate"].flatMap(Self.parseModDate),
            sequenceFormat: seqAttrs["format"],
            sequenceDuration: seqAttrs["duration"].flatMap { try? Rational.parse($0) },
            location: XMLLocation(xpath: xpath)
        )
    }

    // MARK: Metadata

    /// Collects all `<md key value/>` entries inside the element's own
    /// `<metadata>` child (non-recursive — we don't want to pick up
    /// metadata from nested clips under an asset).
    private func metadataEntries(in element: XMLElement) -> [MetadataEntry] {
        guard let metadataElement = element.elements(forName: "metadata").first else {
            return []
        }
        return metadataElement.elements(forName: "md").compactMap { md in
            let attrs = attributeDictionary(md)
            guard let key = attrs["key"] else { return nil }
            return MetadataEntry(key: key, value: attrs["value"] ?? "")
        }
    }

    // MARK: Utilities

    private func attributeDictionary(_ element: XMLElement) -> [String: String] {
        guard let attrs = element.attributes else { return [:] }
        var result: [String: String] = [:]
        for attr in attrs {
            if let name = attr.name, let value = attr.stringValue {
                result[name] = value
            }
        }
        return result
    }

    /// FCPXML emits modDate strings like `"2026-04-15 16:55:17 +0200"`.
    private static let modDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return f
    }()

    public static func parseModDate(_ raw: String) -> Date? {
        modDateFormatter.date(from: raw.trimmingCharacters(in: .whitespaces))
    }
}
