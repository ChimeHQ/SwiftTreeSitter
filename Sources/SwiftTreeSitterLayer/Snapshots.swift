import Foundation

import SwiftTreeSitter

public struct LanguageLayerSnapshot: Sendable {
	public private(set) var tree: Tree
	public let data: LanguageData

	public init(tree: Tree, data: LanguageData, rangeSet: IndexSet? = nil) {
		self.tree = tree
		self.data = data
	}

	public init?(languageLayer: LanguageLayer) {
		guard let tree = languageLayer.state.tree?.copy() else { return nil }

		self.tree = tree
		self.data = languageLayer.languageConfig.data
	}

	public mutating func applyEdit(_ edit: InputEdit) {
		self.tree = tree.edit(edit)!
	}

	var rangeSet: IndexSet {
		var set = IndexSet()

		for tsRange in tree.includedRanges {
			let range = tsRange.bytes.range

			set.insert(integersIn: Range(range) ?? 0..<0)
		}

		return set
	}
}

extension LanguageLayerSnapshot: Queryable {
	/// Run a query against the snapshot.
	public func executeQuery(_ queryDef: Query.Definition, in range: NSRange) throws -> LanguageLayerQueryCursor {
		guard let query = data.queries[queryDef] else {
			throw LanguageLayerError.queryUnavailable(data.name, queryDef)
		}

		let cursor = query.execute(in: tree)

		return LanguageLayerQueryCursor(cursor: cursor, range: range, name: data.name)
	}
}

public struct LanguageLayerTreeSnapshot: Sendable {
	public private(set) var rootSnapshot: LanguageLayerSnapshot
	public private(set) var sublayerSnapshots: [LanguageLayerTreeSnapshot]

	public mutating func applyEdit(_ edit: InputEdit) {
		rootSnapshot.applyEdit(edit)

		for index in sublayerSnapshots.indices {
			sublayerSnapshots[index].applyEdit(edit)
		}
	}

	public func enumerateSnapshots(in set: IndexSet, block: (LanguageLayerSnapshot) throws -> Void) rethrows {
		if set.intersection(rootSnapshot.rangeSet).isEmpty {
			return
		}

		try block(rootSnapshot)

		for sublayer in sublayerSnapshots {
			try sublayer.enumerateSnapshots(in: set, block: block)
		}
	}
}

extension LanguageLayerTreeSnapshot: Queryable {
	public func executeQuery(_ queryDef: Query.Definition, in set: IndexSet) throws -> LanguageTreeQueryCursor {
		let effectiveSet = rootSnapshot.rangeSet.intersection(set)

		let layeredCursors = try effectiveSet.rangeView
			.compactMap { NSRange($0) }
			.map { try rootSnapshot.executeQuery(queryDef, in: $0) }

		var treeQueryCursor = LanguageTreeQueryCursor(subcursors: layeredCursors)

		for sublayer in sublayerSnapshots {
			let subcursor = try sublayer.executeQuery(queryDef, in: set)

			treeQueryCursor.merge(with: subcursor)
		}

		return treeQueryCursor
	}
}
