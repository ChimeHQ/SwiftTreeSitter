// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftTreeSitter",
    products: [
        .library(name: "SwiftTreeSitter", targets: ["SwiftTreeSitter"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "tree-sitter",
                path: "tree-sitter/lib",
                sources: ["src/lib.c"],
                publicHeadersPath: "include",
                cSettings: [.headerSearchPath("src/")]),
        .target(name: "SwiftTreeSitter", dependencies: ["tree-sitter"]),
        .testTarget(name: "SwiftTreeSitterTests", dependencies: ["SwiftTreeSitter"]),
    ]
)
