import XCTest

import TreeSitterDocument
import TestTreeSitterSwift
import SwiftTreeSitter

#if !os(WASI)
final class DocumentLayerTreeTests: XCTestCase {
	private static var swiftConfig: LanguageConfiguration = {
		let language = Language(language: tree_sitter_swift())

		let queryText = """
["func"] @keyword.function
"""

		let highlightQuery = try! Query(language: language, data: queryText.data(using: .utf8)!)

		return LanguageConfiguration(language: language,
									 name: "Swift",
									 queries: [.highlights: highlightQuery])
	}()
}

extension DocumentLayerTreeTests {
	func testExecuteQuery() throws {
		let config = LanguageLayerTree.Configuration()
		let tree = try LanguageLayerTree(rootLanguageConfig: Self.swiftConfig, configuration: config)

		let text = """
func main() {
}
"""
		tree.replaceContent(with: text)

		let cursor = try tree.executeQuery(.highlights, in: NSRange(0..<text.utf16.count))
		let highlights = cursor.highlights()

		let expected = [
			NamedRange(name: "keyword.function", range: NSRange(0..<4), pointRange: Point(row: 0, column: 0)..<Point(row: 0, column: 8)),
		]

		XCTAssertEqual(highlights, expected)
	}
}
#endif
