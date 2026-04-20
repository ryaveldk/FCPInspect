import Foundation

/// An `<asset>` element from resources — typically a source clip on disk.
public struct Asset: Equatable {
    public let id: String
    public let name: String
    public let uid: String?
    public let src: String?
    public let start: Rational?
    public let duration: Rational?
    public let hasVideo: Bool
    public let hasAudio: Bool
    public let format: String?
    public let videoSources: Int?
    public let audioSources: Int?
    public let audioChannels: Int?
    public let audioRate: Int?
    public let metadata: [MetadataEntry]
    public let location: XMLLocation

    public init(
        id: String,
        name: String,
        uid: String?,
        src: String?,
        start: Rational?,
        duration: Rational?,
        hasVideo: Bool,
        hasAudio: Bool,
        format: String?,
        videoSources: Int?,
        audioSources: Int?,
        audioChannels: Int?,
        audioRate: Int?,
        metadata: [MetadataEntry],
        location: XMLLocation
    ) {
        self.id = id
        self.name = name
        self.uid = uid
        self.src = src
        self.start = start
        self.duration = duration
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.format = format
        self.videoSources = videoSources
        self.audioSources = audioSources
        self.audioChannels = audioChannels
        self.audioRate = audioRate
        self.metadata = metadata
        self.location = location
    }
}

/// A `<metadata><md key="…" value="…"/></metadata>` entry.
public struct MetadataEntry: Equatable, Hashable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
