import Foundation

/// Root model produced by `FCPXMLParser`. Represents the subset of FCPXML 1.14
/// that Milestone 1 cares about. Unrecognised elements are discarded silently,
/// but `Media.rawAttributes` and similar escape hatches preserve the raw
/// attribute bag for future expansion.
public struct FCPXMLDocument: Equatable {
    public let version: String
    public let library: Library?
    public let assets: [Asset]
    public let formats: [Format]
    public let medias: [Media]

    /// Total number of `<marker>` elements encountered anywhere in the
    /// document. Cheap aggregate computed by the parser during a single
    /// pass.
    public let markerCount: Int

    /// Total number of `<keyword>` elements encountered anywhere in the
    /// document.
    public let keywordCount: Int

    public init(
        version: String,
        library: Library? = nil,
        assets: [Asset] = [],
        formats: [Format] = [],
        medias: [Media] = [],
        markerCount: Int = 0,
        keywordCount: Int = 0
    ) {
        self.version = version
        self.library = library
        self.assets = assets
        self.formats = formats
        self.medias = medias
        self.markerCount = markerCount
        self.keywordCount = keywordCount
    }

    /// Lookup helpers.
    public func format(withID id: String) -> Format? {
        formats.first { $0.id == id }
    }
}
