import XCTest

import SwiftTreeSitter
import TestTreeSitterSwift

final class NodeTests: XCTestCase {
#if !os(WASI)
	func testTreeNodeLifecycle() throws {
		let language = Language(language: tree_sitter_swift())

		let text = """
func main() {
}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		var tree: MutableTree? = try XCTUnwrap(parser.parse(text))
		let root = try XCTUnwrap(tree?.rootNode)

		tree = nil

		XCTAssertTrue(root.childCount != 0)
	}
#endif
}
