import Foundation

/// A non-simplified rational number used to represent FCPXML time values.
///
/// FCPXML expresses all time quantities as rational fractions ending in `s`,
/// for example `958072/25s`, `1800s`, or `100/2500s`. The exact numerator
/// and denominator matter for frame-accurate comparison, so we preserve the
/// raw values instead of collapsing to `Double`.
public struct Rational: Equatable, Hashable, Comparable, CustomStringConvertible {

    // MARK: Stored

    public let numerator: Int
    public let denominator: Int

    // MARK: Init

    public init(numerator: Int, denominator: Int = 1) {
        precondition(denominator != 0, "Rational denominator may not be zero")
        self.numerator = numerator
        self.denominator = denominator
    }

    // MARK: Derived

    /// Lossy floating-point conversion. Use only for display.
    public var doubleValue: Double {
        Double(numerator) / Double(denominator)
    }

    public var description: String {
        denominator == 1 ? "\(numerator)s" : "\(numerator)/\(denominator)s"
    }

    // MARK: Parsing

    /// Parses FCPXML time strings such as `"0s"`, `"1800s"`, `"958072/25s"`.
    /// Accepts an optional trailing `s` so the parser can also be used on
    /// numeric attributes that happen to carry no unit suffix.
    public static func parse(_ raw: String) throws -> Rational {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.hasSuffix("s") { s.removeLast() }
        guard !s.isEmpty else {
            throw RationalParseError.empty(raw)
        }
        let parts = s.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        switch parts.count {
        case 1:
            guard let n = Int(parts[0]) else {
                throw RationalParseError.invalid(raw)
            }
            return Rational(numerator: n, denominator: 1)
        case 2:
            guard let n = Int(parts[0]), let d = Int(parts[1]), d != 0 else {
                throw RationalParseError.invalid(raw)
            }
            return Rational(numerator: n, denominator: d)
        default:
            throw RationalParseError.invalid(raw)
        }
    }

    // MARK: Comparable

    public static func < (lhs: Rational, rhs: Rational) -> Bool {
        lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }
}

public enum RationalParseError: Error, LocalizedError, Equatable {
    case empty(String)
    case invalid(String)

    public var errorDescription: String? {
        switch self {
        case .empty(let raw): return "Rational is empty: '\(raw)'"
        case .invalid(let raw): return "Rational value is not parseable: '\(raw)'"
        }
    }
}
