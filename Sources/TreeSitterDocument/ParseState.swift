import Foundation

import SwiftTreeSitter

struct ParseState {
	let tree: Tree?

	init(tree: Tree? = nil) {
		self.tree = tree
	}

	func node(in range: Range<UInt32>) -> Node? {
		guard let root = tree?.rootNode else {
			return nil
		}

		return root.descendant(in: range)
	}

	func applyEdit(_ edit: InputEdit) {
		tree?.edit(edit)
	}

	func copy() -> ParseState {
		return ParseState(tree: tree?.copy())
	}
}

extension ParseState {
	func changedByteRanges(for otherState: ParseState) -> [Range<UInt32>] {
		let otherTree = otherState.tree

		switch (tree, otherTree) {
		case (let t1?, let t2?):
			return t1.changedRanges(from: t2).map({ $0.bytes })
		case (nil, let t2?):
			let range = t2.rootNode?.byteRange

			return range.flatMap({ [$0] }) ?? []
		case (_, nil):
			return []
		}
	}

	func changedSet(for otherState: ParseState) -> IndexSet {
		let ranges = changedByteRanges(for: otherState)
			.compactMap({ Range($0.range) })

		var set = IndexSet()

		for range in ranges {
			set.insert(integersIn: range)
		}

		return set
	}
}

extension ParseState {
	func executeQuery(_ query: Query) throws -> QueryCursor {
		guard let node = tree?.rootNode else {
			throw LanguageLayer.Failure.noRootNode
		}

		return query.execute(node: node, in: tree)
	}
}
