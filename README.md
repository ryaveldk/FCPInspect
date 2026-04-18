# FCPInspect

Diagnostic tool for FCPXML files. Identifies structural problems in Final Cut Pro libraries.

## Milestone 1

Core parser, analysis engine with `MulticamDuplicationCheck`, and a CLI.

```
swift build
swift test
.build/debug/fcpinspect-cli test-fixtures/orig_multicam.fcpxmld
```

## Structure

- `FCPInspectCore` — FCPXML 1.14 parser and data model. No UI dependencies.
- `FCPInspectAnalysis` — Check/Finding protocols and `MulticamDuplicationCheck`.
- `fcpinspect-cli` — Command-line frontend that emits a markdown report.

Core and Analysis are UI-free so they can be reused in a future server-side CLI
or scheduled library scanner.
