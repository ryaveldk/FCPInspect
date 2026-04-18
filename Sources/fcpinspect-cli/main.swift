import Foundation
import FCPInspectAnalysis
import FCPInspectCore

// MARK: - Argument handling

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty || args.contains("-h") || args.contains("--help") {
    let usage = """
    Usage: fcpinspect-cli <path> [<path> ...]

    Each <path> may be:
      * a .fcpxml file
      * a .fcpxmld bundle (Info.fcpxml inside is read)
      * a directory (scanned non-recursively for .fcpxml/.fcpxmld)

    When multiple sources are supplied (or a directory yields multiple),
    their <media> lists are merged and all checks run against the combined
    document. Output is markdown on stdout. Exit 0 if no error-level
    findings; 1 otherwise.
    """
    FileHandle.standard(for: args.isEmpty ? .err : .out).write(Data((usage + "\n").utf8))
    exit(args.isEmpty ? 2 : 0)
}

// MARK: - Path expansion

func expand(path rawPath: String) -> [URL] {
    let url = URL(fileURLWithPath: rawPath)
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
        die("No such file or directory: \(rawPath)")
    }

    // .fcpxmld bundles appear as directories to FileManager; treat them as files.
    if url.pathExtension.lowercased() == "fcpxmld" {
        return [url]
    }

    if isDir.boolValue {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        let matches = contents.filter {
            let ext = $0.pathExtension.lowercased()
            return ext == "fcpxml" || ext == "fcpxmld"
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }

        if matches.isEmpty {
            die("Directory contains no .fcpxml or .fcpxmld files: \(rawPath)")
        }
        return matches
    }

    return [url]
}

// MARK: - Main

let sources: [URL] = args.flatMap(expand(path:))

let parser = FCPXMLParser()
var mergedMedias: [Media] = []
var fcpxmlVersion = ""

for source in sources {
    let doc: FCPXMLDocument
    do {
        doc = try parser.parse(path: source)
    } catch {
        die("Failed to parse \(source.lastPathComponent): \(error.localizedDescription)")
    }
    if fcpxmlVersion.isEmpty { fcpxmlVersion = doc.version }
    mergedMedias.append(contentsOf: doc.medias)
}

let mergedDoc = FCPXMLDocument(version: fcpxmlVersion, medias: mergedMedias)

let engine = AnalysisEngine.defaultEngine()
let findings = engine.run(on: mergedDoc)

let report = MarkdownReporter(
    sourceFiles: sources,
    document: mergedDoc,
    checks: engine.checks,
    findings: findings
).render()

FileHandle.standardOutput.write(Data(report.utf8))

let hasError = findings.contains { $0.severity == .error }
exit(hasError ? 1 : 0)

// MARK: - Helpers

func die(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(1)
}

extension FileHandle {
    enum Stream { case out, err }
    static func standard(for stream: Stream) -> FileHandle {
        switch stream {
        case .out: return .standardOutput
        case .err: return .standardError
        }
    }
}
