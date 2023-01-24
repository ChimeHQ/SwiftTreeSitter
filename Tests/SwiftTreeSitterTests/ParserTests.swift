import XCTest

@testable import SwiftTreeSitter
import TestTreeSitterSwift

final class ParserTests: XCTestCase {
	func testSetIncludedRanges() {
		let parser = Parser()

		let range = TSRange(points: Point(row: 1, column: 0)..<Point(row: 1, column: 10),
							bytes: 10..<20)
		parser.includedRanges = [range]

		XCTAssertEqual(parser.includedRanges, [range])
	}

	func testSetTimeout() {
		let parser = Parser()

		parser.timeout = 1.0

		XCTAssertEqual(parser.timeout, 1.0)
	}

#if !os(WASI)
	func testLanguageAccessor() throws {
		let language = Language(language: tree_sitter_swift())

		let parser = Parser()

		try parser.setLanguage(language)

		XCTAssertEqual(parser.language, language)
	}

	func testParseEmojiInEdit() throws {
		let language = Language(language: tree_sitter_swift())

		let text = """
func main() {
}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		let tree = try XCTUnwrap(parser.parse(text))
		let root = try XCTUnwrap(tree.rootNode)

		let funcDecl = try XCTUnwrap(root.child(at: 0))

		XCTAssertEqual(funcDecl.range, NSRange(0..<15))

		let identifier = try XCTUnwrap(funcDecl.child(at: 1))

		XCTAssertEqual(identifier.nodeType, "simple_identifier")
		XCTAssertEqual(identifier.range, NSRange(5..<9))

		let newText = """
func 😃() {
}
"""

		let newEnd = identifier.byteRange.lowerBound + UInt32("😃".utf16.count * 2)

		let edit = InputEdit(startByte: identifier.byteRange.lowerBound,
							 oldEndByte: identifier.byteRange.upperBound,
							 newEndByte: newEnd,
							 startPoint: Point(row: 1, column: 5),
							 oldEndPoint: Point(row: 1, column: 9),
							 newEndPoint: Point(row: 1, column: 7))

		tree.edit(edit)

		let newTree = try XCTUnwrap(parser.parse(tree: tree, string: newText))

		let newRoot = try XCTUnwrap(newTree.rootNode)
		let newIdentifier = try XCTUnwrap(newRoot.child(at: 0)?.child(at: 1))

		XCTAssertEqual(newIdentifier.nodeType, "simple_identifier")
		XCTAssertEqual(newIdentifier.range, NSRange(5..<7))
	}

	func testParseEmojiInTwoConsecutiveEdits() throws {
		let language = Language(language: tree_sitter_swift())

		let textA = """
func main() {
}
"""

		let parser = Parser()
		try parser.setLanguage(language)

		let tree = try XCTUnwrap(parser.parse(textA))

		XCTAssertNotNil(tree.rootNode?.child(at: 0))

		let textB = """
func main😃() {
}
"""

		let endB = 9 * 2 + UInt32("😃".utf16.count * 2)

		let editB = InputEdit(startByte: 9 * 2,
							  oldEndByte: 9 * 2,
							  newEndByte: endB,
							  startPoint: Point(row: 1, column: 9),
							  oldEndPoint: Point(row: 1, column: 9),
							  newEndPoint: Point(row: 1, column: 11))

		tree.edit(editB)

		let treeB = try XCTUnwrap(parser.parse(tree: tree, string: textB))
		XCTAssertNotNil(treeB.rootNode?.child(at: 0))

		let textC = """
func main😃😃() {
}
"""

		let endC = 11 * 2 + UInt32("😃".utf16.count * 2)

		let editC = InputEdit(startByte: 11 * 2,
							  oldEndByte: 11 * 2,
							  newEndByte: endC,
							  startPoint: Point(row: 1, column: 11),
							  oldEndPoint: Point(row: 1, column: 11),
							  newEndPoint: Point(row: 1, column: 13))

		tree.edit(editC)

		let treeC = try XCTUnwrap(parser.parse(tree: tree, string: textC))

		let identifier = try XCTUnwrap(treeC.rootNode?.child(at: 0)?.child(at: 1))

		XCTAssertEqual(identifier.nodeType, "simple_identifier")
		XCTAssertEqual(identifier.range, NSRange(5..<13))
	}
#endif
}
