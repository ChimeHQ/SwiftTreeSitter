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

	init(range: NSRange, delta: Int, oldEndPoint: Point, transformer: Point.LocationTransformer) {
		let startLocation = range.location
		let newEndLocation = range.upperBound + delta

		assert(startLocation >= 0)
		assert(newEndLocation >= startLocation)

		let startPoint = transformer(startLocation) ?? .zero
		let newEndPoint = transformer(newEndLocation) ?? .zero

		assert(oldEndPoint >= startPoint)
		assert(newEndPoint >= startPoint)

		self.init(startByte: UInt32(range.location * 2),
				  oldEndByte: UInt32(range.upperBound * 2),
				  newEndByte: UInt32(newEndLocation * 2),
				  startPoint: startPoint,
				  oldEndPoint: oldEndPoint,
				  newEndPoint: newEndPoint)
	}
}

extension Parser {
	func parse(state: ParseState, readHandler: @escaping Parser.ReadBlock) -> ParseState {
		let newTree = parse(tree: state.tree, readBlock: readHandler)

		return ParseState(tree: newTree)
	}
}

extension MutableTree {
	var includedSet: IndexSet {
		var set = IndexSet()

		for tsRange in includedRanges {
			guard let range = Range(tsRange.bytes.range) else { continue }

			set.insert(integersIn: range)
		}

		return set
	}
}
