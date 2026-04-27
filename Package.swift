// swift-tools-version: 6.0

import Foundation
import PackageDescription

private let aiSeamsDependency: Package.Dependency = {
    let localPath = "../AISeamsKit"
    let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    if FileManager.default.fileExists(atPath: dir.appendingPathComponent(localPath).path) {
        return .package(path: localPath)
    }
    return .package(url: "https://github.com/therealLordtodd/AISeamsKit.git", branch: "main")
}()

let package = Package(
    name: "ExportKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v17),
    ],
    products: [
        .library(name: "ExportKit", targets: ["ExportKit"]),
        .library(name: "ExportKitAISeams", targets: ["ExportKitAISeams"]),
    ],
    dependencies: [
        aiSeamsDependency,
    ],
    targets: [
        .target(name: "ExportKit"),
        .target(name: "ExportKitAISeams", dependencies: [
            "ExportKit",
            .product(name: "AISeamsKit", package: "AISeamsKit"),
        ]),
        .testTarget(
            name: "ExportKitTests",
            dependencies: ["ExportKit"]
        ),
    ]
)
