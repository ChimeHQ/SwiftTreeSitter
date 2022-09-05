import XCTest
@testable import SwiftTreeSitter

final class ParserTests: XCTestCase {
	func testSetIncludedRanges() {
		let parser = Parser()

		let range = TSRange(points: Point(row: 1, column: 0)..<Point(row: 1, column: 10),
							bytes: 10..<20)
		parser.includedRanges = [range]

		XCTAssertEqual(parser.includedRanges, [range])
	}
}
