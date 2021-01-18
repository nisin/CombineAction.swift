// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineAction",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),
    ],
    products: [
        .library(name: "CombineAction", targets: ["CombineAction"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CombineAction",
            dependencies: []),
    ]
)
