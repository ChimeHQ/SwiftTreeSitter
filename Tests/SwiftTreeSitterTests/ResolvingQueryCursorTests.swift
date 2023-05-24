import XCTest

import SwiftTreeSitter
import TestTreeSitterSwift

final class ResolvingQueryCursorTests: XCTestCase {
#if !os(WASI)
	private static var swiftLang = Language(language: tree_sitter_swift())

	func testIsNotPredicate() throws {
		let language = Self.swiftLang
		let queryText = """
("func" @keyword.function (#is-not? group))
"""
		let queryData = try XCTUnwrap(queryText.data(using: .utf8))
		let query = try Query(language: language, data: queryData)

		let text = """
func a() {}
func b() {}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		let tree = try XCTUnwrap(parser.parse(text))
		let root = try XCTUnwrap(tree.rootNode)

		let context = Predicate.Context(textProvider: { _, _ in return nil },
										groupMembershipProvider: {name, range, _ in
			XCTAssertEqual(name, "group")

			return range == NSRange(12..<16)
		})

		let cursor = query.execute(node: root, in: tree)
		let resolvingCursor = ResolvingQueryCursor(cursor: cursor, context: context)

		let expected = [
			NamedRange(name: "keyword.function", range: NSRange(0..<4), pointRange: Point(row: 0, column: 0)..<Point(row: 0, column: 8)),
		]
		let highlights = resolvingCursor.highlights()

		XCTAssertEqual(highlights, expected)
	}
#endif
}
