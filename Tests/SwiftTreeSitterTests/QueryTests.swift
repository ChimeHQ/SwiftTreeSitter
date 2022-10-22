import XCTest

import SwiftTreeSitter
import TestTreeSitterSwift

final class QueryTests: XCTestCase {
#if !os(WASI)
	func testParseQueryWithSetDirectives() throws {
		let language = Language(language: tree_sitter_swift())

		let queryText = """
("func" @keyword.function (#set! abc "def"))
"""
		let queryData = try XCTUnwrap(queryText.data(using: .utf8))
		let query = try Query(language: language, data: queryData)

		let text = """
func main() {
}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		let tree = try XCTUnwrap(parser.parse(text))
		let root = try XCTUnwrap(tree.rootNode)

		let cursor = query.execute(node: root, in: tree)

		let match = try XCTUnwrap(cursor.next())
		XCTAssertEqual(match.metadata["abc"], "def")
	}

	func testParseQueryWithCaptureSetDirectives() throws {
		let language = Language(language: tree_sitter_swift())

		let queryText = """
("func" @keyword.function (#set! @keyword.function abc "def"))
"""
		let queryData = try XCTUnwrap(queryText.data(using: .utf8))
		let query = try Query(language: language, data: queryData)

		let text = """
func main() {
}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		let tree = try XCTUnwrap(parser.parse(text))
		let root = try XCTUnwrap(tree.rootNode)

		let cursor = query.execute(node: root, in: tree)

		let match = try XCTUnwrap(cursor.next())
		XCTAssertTrue(match.metadata.isEmpty)

		let capture = try XCTUnwrap(match.captures.first)

		XCTAssertEqual(capture.metadata["abc"], "def")
	}

	func testHighlightsQuerySorting() throws {
		let language = Language(language: tree_sitter_swift())

		let queryText = """
("func" @a)

("func" @a.b.c)

("func" @a.b)
"""
		let queryData = try XCTUnwrap(queryText.data(using: .utf8))
		let query = try Query(language: language, data: queryData)

		let text = """
func main() {
}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		let tree = try XCTUnwrap(parser.parse(text))
		let root = try XCTUnwrap(tree.rootNode)

		let cursor = query.execute(node: root, in: tree)

		let expected = [
			NamedRange(nameComponents: ["a"], range: NSRange(0..<4)),
			NamedRange(nameComponents: ["a", "b"], range: NSRange(0..<4)),
			NamedRange(nameComponents: ["a", "b", "c"], range: NSRange(0..<4)),
		]

		XCTAssertEqual(cursor.highlights(), expected)
	}
#endif
}
