import Foundation
import AppKit
import FCPInspectAnalysis
import FCPInspectCore

/// One file the user has loaded into the app. Keeping the parsed document
/// alongside the URL means we don't re-parse on every re-run.
struct LoadedSource: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let document: FCPXMLDocument
    let loadedAt: Date

    var displayName: String { url.lastPathComponent }

    static func == (lhs: LoadedSource, rhs: LoadedSource) -> Bool {
        lhs.id == rhs.id
    }
}

/// Top-level observable state for the app. Owns loaded sources, the merged
/// document, the current list of findings, and the user's selection.
@MainActor
final class AppState: ObservableObject {

    // MARK: Published

    @Published private(set) var sources: [LoadedSource] = []
    @Published private(set) var findings: [Finding] = []
    @Published var selectedFindingID: Finding.ID?
    @Published private(set) var errorMessages: [String] = []

    // MARK: Dependencies

    private let parser = FCPXMLParser()
    let engine = AnalysisEngine.defaultEngine()

    // MARK: Derived

    var selectedFinding: Finding? {
        findings.first { $0.id == selectedFindingID }
    }

    var isEmpty: Bool { sources.isEmpty }

    // MARK: Intents

    /// Adds one or more URLs. Directories are expanded into their
    /// `.fcpxml`/`.fcpxmld` children. Errors are surfaced as user-visible
    /// messages instead of thrown — the rest of the batch still loads.
    func add(urls: [URL]) {
        var newSources = sources
        var newErrors: [String] = []
        let expanded = urls.flatMap { Self.expand(url: $0) }

        for url in expanded {
            if newSources.contains(where: { $0.url == url }) { continue }
            do {
                let doc = try parser.parse(path: url)
                newSources.append(LoadedSource(
                    url: url,
                    document: doc,
                    loadedAt: Date()
                ))
            } catch {
                newErrors.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        sources = newSources.sorted { $0.displayName < $1.displayName }
        errorMessages = newErrors
        rerunChecks()
    }

    func remove(_ source: LoadedSource) {
        sources.removeAll { $0.id == source.id }
        rerunChecks()
    }

    func clearAll() {
        sources = []
        findings = []
        selectedFindingID = nil
        errorMessages = []
    }

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = []
        panel.message = "Choose .fcpxml files, .fcpxmld bundles, or a folder."

        if panel.runModal() == .OK {
            add(urls: panel.urls)
        }
    }

    // MARK: Internals

    private func rerunChecks() {
        let merged = FCPXMLDocument(
            version: sources.first?.document.version ?? "",
            medias: sources.flatMap { $0.document.medias }
        )
        findings = engine.run(on: merged)
        if let current = selectedFindingID, !findings.contains(where: { $0.id == current }) {
            selectedFindingID = nil
        }
        if selectedFindingID == nil {
            selectedFindingID = findings.first?.id
        }
    }

    private static func expand(url: URL) -> [URL] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return [] }

        // .fcpxmld bundles look like directories but must be treated as leaves.
        if url.pathExtension.lowercased() == "fcpxmld" { return [url] }

        if isDir.boolValue {
            let children = (try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []
            return children.filter {
                let ext = $0.pathExtension.lowercased()
                return ext == "fcpxml" || ext == "fcpxmld"
            }
        }

        let ext = url.pathExtension.lowercased()
        return (ext == "fcpxml" || ext == "fcpxmld") ? [url] : []
    }
}

// MARK: - Finding identity

extension Finding: Identifiable {
    /// Findings are value types without a natural primary key, but a
    /// hash of the content is stable across re-runs of the same check on
    /// the same document.
    public var id: Int { hashValue }
}
