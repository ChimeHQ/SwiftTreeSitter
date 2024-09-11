import XCTest

import SwiftTreeSitter
import TestTreeSitterSwift

final class LanguageConfigurationTests: XCTestCase {
	func testCreateLanguageWithIncorrectBundleName() throws {
		let language = Language(language: tree_sitter_swift())

		XCTAssertThrowsError(try LanguageConfiguration(language, name: "Swift", bundleName: "abc"))
	}
}
