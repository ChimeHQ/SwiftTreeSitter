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
		.target(name: "TestTreeSitterSwift",
				path: "tree-sitter-swift",
				sources: ["src/parser.c", "src/scanner.c"],
				publicHeadersPath: "bindings/swift",
				cSettings: [.headerSearchPath("src")]),
        .target(name: "SwiftTreeSitter", dependencies: ["tree-sitter"]),
        .testTarget(name: "SwiftTreeSitterTests",
					dependencies: ["SwiftTreeSitter", "TestTreeSitterSwift"]),
		.target(name: "TreeSitterDocument", dependencies: ["SwiftTreeSitter"]),
		.testTarget(name: "TreeSitterDocumentTests",
					dependencies: ["TreeSitterDocument", "TestTreeSitterSwift"]),
    ]
)
