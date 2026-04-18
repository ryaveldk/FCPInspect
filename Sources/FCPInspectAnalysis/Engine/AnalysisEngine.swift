import Foundation
import FCPInspectCore

/// Runs a list of checks against a parsed document and collects the
/// findings. Milestone 1 is deliberately simple — no parallelism, no
/// caching, no inter-check dependencies.
public struct AnalysisEngine {

    public let checks: [Check]

    public init(checks: [Check]) {
        self.checks = checks
    }

    /// Engine with the default Milestone 1 check set.
    public static func defaultEngine() -> AnalysisEngine {
        AnalysisEngine(checks: [MulticamDuplicationCheck()])
    }

    public func run(on document: FCPXMLDocument) -> [Finding] {
        checks.flatMap { $0.run(on: document) }
    }
}
