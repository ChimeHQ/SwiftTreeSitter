import Foundation
import SwiftTreeSitter

extension Point {
	public typealias LocationTransformer = (Int) -> Point?
}

extension InputEdit {
	init?(range: NSRange, delta: Int, oldEndPoint: Point, transformer: Point.LocationTransformer? = nil) {
		let startLocation = range.location
		let newEndLocation = range.upperBound + delta

		if newEndLocation < 0 {
			assertionFailure("invalid range/delta")
			return nil
		}

		let startPoint = transformer?(startLocation)
		let newEndPoint = transformer?(newEndLocation)

		if transformer != nil {
			assert(startPoint != nil)
			assert(newEndPoint != nil)
		}

		self.init(startByte: UInt32(range.location * 2),
				  oldEndByte: UInt32(range.upperBound * 2),
				  newEndByte: UInt32(newEndLocation * 2),
				  startPoint: startPoint ?? .zero,
				  oldEndPoint: oldEndPoint,
				  newEndPoint: newEndPoint ?? .zero)
	}
}

extension Parser {
	func parse(state: ParseState, string: String, limit: Int? = nil) -> ParseState {
		let newTree = parse(tree: state.tree, string: string, limit: limit)

		return ParseState(tree: newTree)
	}

	func parse(state: ParseState, readHandler: @escaping Parser.ReadBlock) -> ParseState {
		let newTree = parse(tree: state.tree, readBlock: readHandler)

		return ParseState(tree: newTree)
	}
}
