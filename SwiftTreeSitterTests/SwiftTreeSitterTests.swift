import XCTest
import tree_sitter_go
@testable import SwiftTreeSitter

class SwiftTreeSitterTests: XCTestCase {
    func testSimpleParse() throws {
        let parser = Parser()

        try parser.setLanguage(tree_sitter_go())

        let tree = try XCTUnwrap(parser.parse("var foo int"))
        let root = try XCTUnwrap(tree.rootNode)

        XCTAssertEqual(root.childCount, 2)
        XCTAssertEqual(root.child(at: 0)?.nodeType, "var_declaration")
        XCTAssertEqual(root.child(at: 1)?.nodeType, "\n")
    }
    
    func testFields() throws {
        let lang = Language(language: tree_sitter_go())
        
        XCTAssertEqual(lang.fieldCount, 33)
        XCTAssertEqual(lang.fieldName(for: 13), "function")
    }
}
