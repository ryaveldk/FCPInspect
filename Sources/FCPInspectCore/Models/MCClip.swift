import Foundation

/// A timeline `<mc-clip>` that references a multicam media object.
///
/// Currently unused by Milestone 1 checks but parsed so Milestone 2 can
/// correlate timeline usage with ghost multicams without changes to the
/// parser.
public struct MCClip: Equatable {
    public let ref: String
    public let name: String?
    public let start: Rational?
    public let duration: Rational?
    public let modDateRaw: String?
    public let sources: [MCSource]
    public let location: XMLLocation

    public init(
        ref: String,
        name: String?,
        start: Rational?,
        duration: Rational?,
        modDateRaw: String?,
        sources: [MCSource],
        location: XMLLocation
    ) {
        self.ref = ref
        self.name = name
        self.start = start
        self.duration = duration
        self.modDateRaw = modDateRaw
        self.sources = sources
        self.location = location
    }
}

public struct MCSource: Equatable {
    public let angleID: String
    public let srcEnable: String?
    public let audioRoleSources: [AudioRoleSource]
    public let location: XMLLocation

    public init(
        angleID: String,
        srcEnable: String?,
        audioRoleSources: [AudioRoleSource],
        location: XMLLocation
    ) {
        self.angleID = angleID
        self.srcEnable = srcEnable
        self.audioRoleSources = audioRoleSources
        self.location = location
    }
}

public struct AudioRoleSource: Equatable {
    public let role: String
    public let active: Bool?
    public let location: XMLLocation

    public init(role: String, active: Bool?, location: XMLLocation) {
        self.role = role
        self.active = active
        self.location = location
    }
}
