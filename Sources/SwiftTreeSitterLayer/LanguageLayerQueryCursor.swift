import Foundation

import SwiftTreeSitter
import enum SwiftTreeSitter.Predicate

public struct LanguageLayerQueryCursor {
	public struct Target {
		let tree: Tree
		let query: Query
		let depth: Int
		let name: String
	}

	private let ranges: [NSRange]
	public let target: Target
	private var activeCursor: QueryCursor?
	private var index: Int

	init(target: LanguageLayerQueryCursor.Target, set: IndexSet) {
		self.target = target
		self.ranges = set.rangeView.compactMap({ NSRange($0) })
		self.index = ranges.index(before: ranges.startIndex)

		advanceRange()
	}

//	init(query: Query, tree: Tree, set: IndexSet, depth: Int, languageName: String) {
//		
//	}
}

extension LanguageLayerQueryCursor: Sequence, IteratorProtocol {
	public typealias Element = QueryMatch

	private mutating func advanceRange() {
		self.index += 1
		guard index < ranges.endIndex else {
			self.activeCursor = nil
			return
		}

		let range = ranges[index]

		self.activeCursor = target.query.execute(in: target.tree, depth: target.depth)

		self.activeCursor?.setRange(range)
	}

	public mutating func next() -> Element? {
		while activeCursor != nil {
			if let match = activeCursor?.next() {
				return match
			}

			// our match has returned nil, do we need to advance to the next range?
			self.advanceRange()
		}

		return nil
	}
}

public struct LanguageTreeQueryCursor {
	private var activeCursor: LanguageLayerQueryCursor?
	private let targets: [LanguageLayerQueryCursor.Target]
	private var index: Int
	private var set: IndexSet

	init(set: IndexSet, targets: [LanguageLayerQueryCursor.Target]) {
		self.set = set
		self.targets = targets
		self.index = targets.index(before: targets.startIndex)

		advanceCursor()
	}
}

extension LanguageTreeQueryCursor: Sequence, IteratorProtocol {
	public typealias Element = QueryMatch

	private mutating func advanceCursor() {
		self.index += 1
		guard index < targets.endIndex else {
			self.activeCursor = nil
			return
		}

		self.activeCursor = LanguageLayerQueryCursor(target: targets[index], set: set)
	}

	private mutating func expandSet(_ range: NSRange?) {
		if let range = range {
			self.set.formUnion(IndexSet(integersIn: range))
		}
	}

	public mutating func next() -> Element? {
		while activeCursor != nil {
			if let match = activeCursor?.next() {
				// matches can occur outside of our target and can affect sublayer queries
				expandSet(match.range)

				return match
			}

			// our match has returned nil, do we need to advance to the next cursor?
			self.advanceCursor()
		}

		return nil
	}

}
