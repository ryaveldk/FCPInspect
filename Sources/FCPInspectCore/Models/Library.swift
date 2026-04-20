import Foundation

/// Optional top-level `<library>` element. Its `location` is the file://
/// URL to the `.fcpbundle` that produced the XML — often useful because
/// the path contains the originating user's home directory.
public struct Library: Equatable {
    public let location: String?
    public let events: [Event]
    public let locationURL: URL?

    public init(location: String?, events: [Event]) {
        self.location = location
        self.events = events
        self.locationURL = location.flatMap(URL.init(string:))
    }

    /// Username derived from the library's location path, if present.
    /// Works for standard `/Users/<name>/…` paths.
    public var originatingUsername: String? {
        guard let path = locationURL?.path else { return nil }
        let parts = path.split(separator: "/", omittingEmptySubsequences: true)
        guard parts.count >= 2, parts[0] == "Users" else { return nil }
        return String(parts[1])
    }
}

/// A `<event>` in the library.
public struct Event: Equatable {
    public let name: String
    public let uid: String?
    public let projects: [Project]

    public init(name: String, uid: String?, projects: [Project]) {
        self.name = name
        self.uid = uid
        self.projects = projects
    }
}

/// A `<project>` inside an event. A project owns exactly one sequence
/// (the timeline).
public struct Project: Equatable {
    public let name: String
    public let id: String?
    public let uid: String?
    public let modDateRaw: String?
    public let modDate: Date?
    public let sequenceFormat: String?
    public let sequenceDuration: Rational?
    public let location: XMLLocation

    public init(
        name: String,
        id: String?,
        uid: String?,
        modDateRaw: String?,
        modDate: Date?,
        sequenceFormat: String?,
        sequenceDuration: Rational?,
        location: XMLLocation
    ) {
        self.name = name
        self.id = id
        self.uid = uid
        self.modDateRaw = modDateRaw
        self.modDate = modDate
        self.sequenceFormat = sequenceFormat
        self.sequenceDuration = sequenceDuration
        self.location = location
    }
}
