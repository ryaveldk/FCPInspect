import Foundation

/// Root model produced by `FCPXMLParser`. Represents the subset of FCPXML 1.14
/// that Milestone 1 cares about. Unrecognised elements are discarded silently,
/// but `Media.rawAttributes` and similar escape hatches preserve the raw
/// attribute bag for future expansion.
public struct FCPXMLDocument: Equatable {
    public let version: String
    public let medias: [Media]

    public init(version: String, medias: [Media]) {
        self.version = version
        self.medias = medias
    }
}
