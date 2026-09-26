// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Corgify",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "CorgifyCore", targets: ["CorgifyCore"]),
        .executable(name: "corgify-verify", targets: ["corgify-verify"]),
        .executable(name: "corgify-analyze", targets: ["corgify-analyze"])
    ],
    targets: [
        .target(
            name: "CorgifyCore",
            path: "Sources/CorgifyCore"
        ),
        // Dependency-free verification runner. XCTest and Swift Testing both
        // require a full Xcode install; this runs with only the Swift
        // toolchain, so the core mapping is verifiable in a clean CI box.
        .executableTarget(
            name: "corgify-verify",
            dependencies: ["CorgifyCore"],
            path: "Sources/corgify-verify"
        ),
        // Runs the real Vision pipeline over photo files so the landmark math
        // and the HumanRange constants can be checked against actual faces.
        .executableTarget(
            name: "corgify-analyze",
            dependencies: ["CorgifyCore"],
            path: "Sources/corgify-analyze"
        ),
        .testTarget(
            name: "CorgifyCoreTests",
            dependencies: ["CorgifyCore"],
            path: "Tests/CorgifyCoreTests"
        )
    ]
)
