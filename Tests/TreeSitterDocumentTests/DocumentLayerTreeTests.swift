import XCTest

import TreeSitterDocument
import TestTreeSitterSwift
import SwiftTreeSitter

extension Query {
	convenience init(language: Language, text: String) throws {
		let data = text.data(using: .utf8)!

		try self.init(language: language, data: data)
	}
}

#if !os(WASI)
final class DocumentLayerTreeTests: XCTestCase {
	private static let language = Language(language: tree_sitter_swift())

	func testExecuteQuery() throws {
		let config = DocumentLayerTree.Configuration(language: Self.language)
		let tree = try DocumentLayerTree(configuration: config)

		let text = """
func main() {
}
"""
		tree.replaceContent(with: text)

		let queryText = """
("func" @keyword.function)
"""
		let query = try Query(language: Self.language, text: queryText)

		let cursor = try tree.executeQuery(query, in: NSRange(0..<text.utf16.count))
		let highlights = cursor.highlights()

		let expected = [
			NamedRange(name: "keyword.function", range: NSRange(0..<4), pointRange: Point(row: 0, column: 0)..<Point(row: 0, column: 8)),
		]

		XCTAssertEqual(highlights, expected)
	}

	func testInjectedLanguge() throws {
		let provider: DocumentLayerTree.LanguageProvider = {
			XCTAssertEqual($0, "Swift")

			return Self.language
		}

		let config = DocumentLayerTree.Configuration(language: Self.language,
												injectedLanguageProvider: provider)

		let tree = try DocumentLayerTree(configuration: config)

		let text = """
func main() {
	let string = "abc"
}
"""
		tree.replaceContent(with: text)

		let queryText = """
((function_body) @injection.content (#set! injection.language "swift"))
"""
		let query = try Query(language: Self.language, text: queryText)

		let cursor = try tree.executeQuery(query, in: NSRange(0..<text.utf16.count))
		let injections = cursor.injections()

		let expected = [
			NamedRange(name: "swift", range: NSRange(12..<35), pointRange: Point(row: 0, column: 24)..<Point(row: 2, column: 2)),
		]

		XCTAssertEqual(injections, expected)
	}
}
#endif
