// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
	name: "SwiftTreeSitter",
	products: [
		.library(name: "SwiftTreeSitter", targets: ["SwiftTreeSitter"]),
		.library(name: "SwiftTreeSitterLayer", targets: ["SwiftTreeSitterLayer"]),
	],
	targets: [
		.target(
			name: "tree-sitter",
			path: "tree-sitter/lib",
			sources: ["src/lib.c"],
			publicHeadersPath: "include",
			cSettings: [.headerSearchPath("src/")]
		),
		.target(
			name: "TestTreeSitterSwift",
			path: "tree-sitter-swift",
			sources: ["src/parser.c", "src/scanner.c"],
			publicHeadersPath: "bindings/swift",
			cSettings: [.headerSearchPath("src")]
		),
		.target(
			name: "SwiftTreeSitter",
			dependencies: ["tree-sitter"],
			swiftSettings: settings
		),
		.testTarget(
			name: "SwiftTreeSitterTests",
			dependencies: ["SwiftTreeSitter", "TestTreeSitterSwift"],
			swiftSettings: settings
		),
		.target(
			name: "SwiftTreeSitterLayer",
			dependencies: ["SwiftTreeSitter"],
			swiftSettings: settings
		),
		.testTarget(
			name: "SwiftTreeSitterLayerTests",
			dependencies: ["SwiftTreeSitterLayer", "TestTreeSitterSwift"],
			swiftSettings: settings
		),
	]
)

