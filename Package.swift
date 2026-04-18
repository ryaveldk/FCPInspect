// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FCPInspect",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "FCPInspectCore", targets: ["FCPInspectCore"]),
        .library(name: "FCPInspectAnalysis", targets: ["FCPInspectAnalysis"]),
        .executable(name: "fcpinspect-cli", targets: ["fcpinspect-cli"])
    ],
    targets: [
        .target(
            name: "FCPInspectCore",
            path: "Sources/FCPInspectCore"
        ),
        .target(
            name: "FCPInspectAnalysis",
            dependencies: ["FCPInspectCore"],
            path: "Sources/FCPInspectAnalysis"
        ),
        .executableTarget(
            name: "fcpinspect-cli",
            dependencies: ["FCPInspectCore", "FCPInspectAnalysis"],
            path: "Sources/fcpinspect-cli"
        ),
        .testTarget(
            name: "FCPInspectCoreTests",
            dependencies: ["FCPInspectCore"],
            path: "Tests/FCPInspectCoreTests"
        ),
        .testTarget(
            name: "FCPInspectAnalysisTests",
            dependencies: ["FCPInspectCore", "FCPInspectAnalysis"],
            path: "Tests/FCPInspectAnalysisTests"
        )
    ]
)
