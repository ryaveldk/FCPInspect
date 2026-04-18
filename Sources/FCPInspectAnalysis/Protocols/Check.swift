import Foundation
import FCPInspectCore

/// A single analysis step. Checks are stateless and pure: given a document
/// they return zero or more findings. This lets the engine parallelise or
/// reorder them safely and makes them trivial to unit test.
public protocol Check {
    /// Stable identifier, e.g. `"multicam-duplication"`. Used for filtering
    /// checks from the CLI and for deduplicating findings across runs.
    var id: String { get }

    /// Human-readable title of the check, shown in reporting UIs.
    var title: String { get }

    func run(on document: FCPXMLDocument) -> [Finding]
}
