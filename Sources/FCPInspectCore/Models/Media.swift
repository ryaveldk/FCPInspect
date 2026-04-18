import Foundation

/// A `<media>` element in the resources section. For Milestone 1 we only
/// need the attributes relevant to multicam identity plus any nested
/// `<multicam>`.
public struct Media: Equatable {
    public let id: String
    public let name: String
    public let uid: String

    /// Raw `modDate` attribute value, preserved verbatim for reporting.
    public let modDateRaw: String?

    /// Parsed `modDate` when the attribute is present and well-formed. Used
    /// to rank duplicate multicams by recency.
    public let modDate: Date?

    public let multicam: Multicam?
    public let location: XMLLocation

    /// Escape hatch: every attribute observed on the element, including ones
    /// the typed model does not explicitly surface. Lets future checks grow
    /// without reparsing.
    public let rawAttributes: [String: String]

    public init(
        id: String,
        name: String,
        uid: String,
        modDateRaw: String?,
        modDate: Date?,
        multicam: Multicam?,
        location: XMLLocation,
        rawAttributes: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.uid = uid
        self.modDateRaw = modDateRaw
        self.modDate = modDate
        self.multicam = multicam
        self.location = location
        self.rawAttributes = rawAttributes
    }
}
