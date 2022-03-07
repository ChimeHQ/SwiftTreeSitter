// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftTreeSitter",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "SwiftTreeSitter", targets: ["SwiftTreeSitter"]),
    ],
    dependencies: [
      .package(url: "https://github.com/krzyzanowskim/tree-sitter-xcframework", from: "0.206.2")
    ],
    targets: [
      .target(name: "SwiftTreeSitter", dependencies: ["tree_sitter"]),
      .testTarget(name: "SwiftTreeSitterTests", dependencies: ["SwiftTreeSitter"]),
    ]
)
