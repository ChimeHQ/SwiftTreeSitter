// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TreeSitterExample",
    products: [
        .library(name: "TreeSitterExample", targets: ["TreeSitterExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter"),
    ],
    targets: [
        .target(name: "TreeSitterExample", dependencies: [
            "SwiftTreeSitter",
        ]),
    ]
)
