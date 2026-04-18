import Foundation

/// A `<multicam>` element nested inside a `<media>` element.
public struct Multicam: Equatable {
    public let format: String?
    public let tcStart: Rational?
    public let tcFormat: String?
    public let angles: [MCAngle]
    public let location: XMLLocation

    public init(
        format: String?,
        tcStart: Rational?,
        tcFormat: String?,
        angles: [MCAngle],
        location: XMLLocation
    ) {
        self.format = format
        self.tcStart = tcStart
        self.tcFormat = tcFormat
        self.angles = angles
        self.location = location
    }
}

/// A `<mc-angle>` element within a multicam. Its `angleID` is the stable
/// identifier used when calculating multicam fingerprints.
public struct MCAngle: Equatable {
    public let name: String
    public let angleID: String
    public let assetClips: [AssetClip]
    public let location: XMLLocation

    public init(
        name: String,
        angleID: String,
        assetClips: [AssetClip],
        location: XMLLocation
    ) {
        self.name = name
        self.angleID = angleID
        self.assetClips = assetClips
        self.location = location
    }
}

/// A `<asset-clip>` inside an `<mc-angle>`.
public struct AssetClip: Equatable {
    public let ref: String
    public let offset: Rational?
    public let name: String?
    public let start: Rational?
    public let duration: Rational?
    public let tcFormat: String?
    public let audioRole: String?
    public let location: XMLLocation

    public init(
        ref: String,
        offset: Rational?,
        name: String?,
        start: Rational?,
        duration: Rational?,
        tcFormat: String?,
        audioRole: String?,
        location: XMLLocation
    ) {
        self.ref = ref
        self.offset = offset
        self.name = name
        self.start = start
        self.duration = duration
        self.tcFormat = tcFormat
        self.audioRole = audioRole
        self.location = location
    }
}
