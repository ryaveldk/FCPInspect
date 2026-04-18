import Foundation

/// A pointer back into the source XML for a parsed element. Used by
/// `Finding`s so that a downstream reporter can show the user where a
/// problem was detected.
public struct XMLLocation: Equatable, Hashable, Codable {
    /// Simple XPath-like expression, e.g. `/fcpxml/resources/media[1]/multicam`.
    public let xpath: String

    public init(xpath: String) {
        self.xpath = xpath
    }
}
