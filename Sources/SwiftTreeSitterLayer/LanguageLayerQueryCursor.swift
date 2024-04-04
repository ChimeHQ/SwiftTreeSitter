import Foundation

import SwiftTreeSitter
import enum SwiftTreeSitter.Predicate

public struct LanguageLayerQueryCursor {
	private let ranges: [NSRange]
	private let query: Query
	private let tree: Tree
	private var activeCursor: QueryCursor?
	private var index: Int
	public let depth: Int
	public let languageName: String

	init(query: Query, tree: Tree, set: IndexSet, depth: Int, languageName: String) {
		self.tree = tree
		self.query = query
		self.ranges = set.rangeView.compactMap({ NSRange($0) })
		self.index = ranges.index(before: ranges.startIndex)
		self.depth = depth
		self.languageName = languageName

		advanceRange()
	}

	init(target: LanguageTreeQueryCursor.Target, set: IndexSet) {
		self.init(
			query: target.1,
			tree: target.0,
			set: set,
			depth: target.2,
			languageName: target.3
		)
	}
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

		self.activeCursor = query.execute(in: tree, depth: depth)

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
	typealias Target = (Tree, Query, Int, String)

	private var activeCursor: LanguageLayerQueryCursor?
	private let targets: [Target]
	private var index: Int
	private var set: IndexSet

	init(set: IndexSet, targets: [Target]) {
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
