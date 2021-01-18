# CombineAction.swift
Combine Framework version ReactiveSwift's Action like class

## Installation

### Swift Package Manager



```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MyLibrary",
    products: [
        .library(name: "MyLibrary", targets: ["MyLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nisin/CombineAction.swift.git", .branch("main")),
    ],
    targets: [
        .target(name: "MyLibrary", dependencies: ["CombineAction"]),
    ]
)
```