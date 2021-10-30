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
      .systemLibrary(name: "tree_sitter", path: "Ctree-sitter", pkgConfig: "tree-sitter"),
      .systemLibrary(name: "tree_sitter_go", path: "Ctree-sitter-go", pkgConfig: "tree-sitter-go"),
      .target(name: "SwiftTreeSitter",
              dependencies: ["tree_sitter", "tree_sitter_go"],
              path: "SwiftTreeSitter/"),
        .testTarget(name: "SwiftTreeSitterTests", dependencies: ["SwiftTreeSitter"], path: "SwiftTreeSitterTests/")
    ]
)
