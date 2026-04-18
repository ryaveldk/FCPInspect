import SwiftUI

/// Studio Monolith visual identity — dark charcoal surfaces with a cyan
/// accent. Values are grouped here so that a colour tweak only requires
/// editing this one file.
enum Theme {

    // MARK: Surfaces

    static let canvas = Color(red: 0.10, green: 0.10, blue: 0.12)          // ~#1a1a1e
    static let surface = Color(red: 0.13, green: 0.14, blue: 0.17)         // ~#21232b
    static let surfaceElevated = Color(red: 0.17, green: 0.18, blue: 0.21) // ~#2b2e35
    static let stroke = Color(red: 0.22, green: 0.23, blue: 0.27)

    // MARK: Brand

    static let cyan = Color(red: 0.00, green: 0.82, blue: 0.91)      // primary accent
    static let cyanMuted = Color(red: 0.00, green: 0.60, blue: 0.68)
    static let cyanSoft = Color(red: 0.00, green: 0.82, blue: 0.91).opacity(0.18)

    // MARK: Text

    static let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.94)
    static let textSecondary = Color(red: 0.64, green: 0.66, blue: 0.70)
    static let textTertiary = Color(red: 0.45, green: 0.47, blue: 0.51)

    // MARK: Severity

    static let severityInfo = Color(red: 0.42, green: 0.70, blue: 0.92)
    static let severityWarning = Color(red: 0.96, green: 0.64, blue: 0.26)
    static let severityError = Color(red: 0.95, green: 0.38, blue: 0.38)
}
