import Foundation

/// A `<format>` element from resources — describes video format used
/// by assets/sequences that reference it.
public struct Format: Equatable {
    public let id: String
    public let name: String?
    public let frameDuration: Rational?
    public let width: Int?
    public let height: Int?
    public let colorSpace: String?
    public let location: XMLLocation

    public init(
        id: String,
        name: String?,
        frameDuration: Rational?,
        width: Int?,
        height: Int?,
        colorSpace: String?,
        location: XMLLocation
    ) {
        self.id = id
        self.name = name
        self.frameDuration = frameDuration
        self.width = width
        self.height = height
        self.colorSpace = colorSpace
        self.location = location
    }

    /// Frames per second derived from `frameDuration`, if present.
    /// FCPXML stores frameDuration as the inverse of fps (e.g. `100/2500s`
    /// = 0.04s per frame = 25 fps).
    public var framesPerSecond: Double? {
        guard let fd = frameDuration, fd.numerator != 0 else { return nil }
        return Double(fd.denominator) / Double(fd.numerator)
    }

    /// Human-readable resolution like `"1920×1080"`.
    public var resolution: String? {
        guard let w = width, let h = height else { return nil }
        return "\(w)×\(h)"
    }
}
