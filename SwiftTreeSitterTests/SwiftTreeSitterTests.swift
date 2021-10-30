//
//  SwiftTreeSitterTests.swift
//  SwiftTreeSitterTests
//
//  Created by Matt Massicotte on 2018-12-17.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import XCTest
@testable import SwiftTreeSitter

class SwiftTreeSitterTests: XCTestCase {
    func testSimpleParse() throws {
        let parser = Parser()

        try parser.setLanguage(.go)

        let tree = try XCTUnwrap(parser.parse("var foo int"))
        let root = try XCTUnwrap(tree.rootNode)

        XCTAssertEqual(root.childCount, 2)
        XCTAssertEqual(root.child(at: 0)?.nodeType, "var_declaration")
        XCTAssertEqual(root.child(at: 1)?.nodeType, "\n")
    }
    
    func testFields() throws {
        let lang = Language.go
        
        XCTAssertEqual(lang.fieldCount, 33)
        XCTAssertEqual(lang.fieldName(for: 13), "function")
    }
}
