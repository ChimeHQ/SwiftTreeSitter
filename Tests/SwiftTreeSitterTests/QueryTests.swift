import XCTest
import SwiftTreeSitter
//import tree_sitter_language_resources

final class QueryTests: XCTestCase {
//    static let rubyQueryWithIsNotLocal = """
//((identifier) @function.method
// (#is-not? local))
//"""
//
//    static let rubyQueryWithNoPredicates = """
//(identifier) @function.method
//"""
//
//    func testParseQueryWithPredicates() throws {
//        let ruby = LanguageResource.ruby
//        let language = Language(language: ruby.parser)
//
//        let queryData = try XCTUnwrap(QueryTests.rubyQueryWithIsNotLocal.data(using: .utf8))
//        let query = try Query(language: language, data: queryData)
//
//        XCTAssertEqual(query.patternCount, 1)
//        XCTAssertTrue(query.hasPredicates)
//    }
//
//    func testParseQueryWithNoPredicates() throws {
//        let ruby = LanguageResource.ruby
//        let language = Language(language: ruby.parser)
//
//        let queryData = try XCTUnwrap(QueryTests.rubyQueryWithNoPredicates.data(using: .utf8))
//        let query = try Query(language: language, data: queryData)
//
//        XCTAssertEqual(query.patternCount, 1)
//        XCTAssertFalse(query.hasPredicates)
//    }
}
