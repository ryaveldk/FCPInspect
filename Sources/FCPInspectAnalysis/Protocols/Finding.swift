import Foundation
import FCPInspectCore

/// A single problem (or informational note) produced by a `Check`.
public struct Finding: Equatable, Hashable {
    public enum Severity: String, Equatable, Hashable, Comparable {
        case info
        case warning
        case error

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rank < rhs.rank
        }

        private var rank: Int {
            switch self {
            case .info: return 0
            case .warning: return 1
            case .error: return 2
            }
        }
    }

    public let severity: Severity
    public let checkID: String
    public let title: String

    /// Rich markdown body describing the finding. Reporters typically
    /// emit this verbatim under a heading derived from `title`.
    public let description: String

    /// Zero or more XML locations relevant to the finding, in the order
    /// that makes sense to present to the user.
    public let location: [XMLLocation]

    public let suggestedRemediation: String?

    public init(
        severity: Severity,
        checkID: String,
        title: String,
        description: String,
        location: [XMLLocation],
        suggestedRemediation: String?
    ) {
        self.severity = severity
        self.checkID = checkID
        self.title = title
        self.description = description
        self.location = location
        self.suggestedRemediation = suggestedRemediation
    }
}
