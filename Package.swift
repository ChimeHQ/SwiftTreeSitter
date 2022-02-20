// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftTreeSitter",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "SwiftTreeSitter", targets: ["SwiftTreeSitter"]),
    ],
    dependencies: [],
    targets: [
      .systemLibrary(name: "tree_sitter", pkgConfig: "tree-sitter"),
      .target(name: "SwiftTreeSitter", dependencies: ["tree_sitter"]),
      .testTarget(name: "SwiftTreeSitterTests", dependencies: ["SwiftTreeSitter"]),
    ]
)
