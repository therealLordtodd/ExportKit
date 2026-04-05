// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ExportKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v17),
    ],
    products: [
        .library(name: "ExportKit", targets: ["ExportKit"]),
    ],
    targets: [
        .target(name: "ExportKit"),
        .testTarget(
            name: "ExportKitTests",
            dependencies: ["ExportKit"]
        ),
    ]
)
