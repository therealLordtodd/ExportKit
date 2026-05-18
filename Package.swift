// swift-tools-version: 6.0

import Foundation
import PackageDescription

private let aiSeamsDependency: Package.Dependency = {
    let localPath = "../AISeamsKit"
    let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

    // Refuse local-path when this manifest is being evaluated as a transitive
    // dependency (under SwiftPM's `.build/checkouts/`). See Marple commit
    // 39d67d6 for the full background — short version: the sibling-fetch
    // creates a conflicting-identity collision with the upstream's URL dep.
    let isTransitiveCheckout = dir.path.contains("/.build/checkouts/")

    if !isTransitiveCheckout,
       FileManager.default.fileExists(atPath: dir.appendingPathComponent(localPath).path) {
        return .package(path: localPath)
    }
    return .package(url: "https://github.com/therealLordtodd/AISeamsKit.git", branch: "main")
}()

let package = Package(
    name: "ExportKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v15),
    ],
    products: [
        .library(name: "ExportKit", targets: ["ExportKit"]),
        .library(name: "ExportKitAISeams", targets: ["ExportKitAISeams"]),
        .library(name: "ExportKitMarpleProbes", targets: ["ExportKitMarpleProbes"]),
    ],
    dependencies: [
        aiSeamsDependency,
        .package(path: "../Marple"),
    ],
    targets: [
        .target(name: "ExportKit"),
        .target(name: "ExportKitAISeams", dependencies: [
            "ExportKit",
            .product(name: "AISeamsKit", package: "AISeamsKit"),
        ]),
        .target(
            name: "ExportKitMarpleProbes",
            dependencies: [
                "ExportKit",
                .product(name: "MarpleCore", package: "Marple"),
            ],
            exclude: ["CONVENTIONS.md"]
        ),
        .testTarget(
            name: "ExportKitTests",
            dependencies: ["ExportKit"]
        ),
        .testTarget(
            name: "ExportKitMarpleProbesTests",
            dependencies: [
                "ExportKitMarpleProbes",
                .product(name: "MarpleCore", package: "Marple"),
            ]
        ),
    ]
)
