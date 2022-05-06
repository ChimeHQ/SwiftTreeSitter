// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftTreeSitter",
    platforms: [.macOS(.v10_13), .iOS(.v11)],
    products: [
        .library(name: "SwiftTreeSitter", targets: ["SwiftTreeSitter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mattmassicotte/tree-sitter", .branch("feature/swift-package"))
    ],
    targets: [
        .target(name: "SwiftTreeSitter", dependencies: ["tree-sitter"]),
        .testTarget(name: "SwiftTreeSitterTests", dependencies: ["SwiftTreeSitter"]),
    ]
)
