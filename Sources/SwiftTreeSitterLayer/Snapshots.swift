import Foundation

import SwiftTreeSitter

public struct LanguageLayerSnapshot: Sendable {
	public private(set) var tree: Tree
	public let data: LanguageData
	public let depth: Int

	public init(tree: Tree, data: LanguageData, depth: Int) {
		self.tree = tree
		self.data = data
		self.depth = depth
	}

	public init?(languageLayer: LanguageLayer) {
		guard let tree = languageLayer.state.tree?.copy() else { return nil }

		self.init(tree: tree, data: languageLayer.languageConfig.data, depth: languageLayer.depth)
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

	func queryTarget(for queryDef: Query.Definition) -> LanguageTreeQueryCursor.Target? {
		guard let query = data.queries[queryDef] else {
			return nil
		}

		return (tree, query, depth)
	}
}

extension LanguageLayerSnapshot: Queryable {
	/// Run a query against the snapshot.
	public func executeQuery(_ queryDef: Query.Definition, in set: IndexSet) throws -> LanguageLayerQueryCursor {
		guard let query = data.queries[queryDef] else {
			throw LanguageLayerError.queryUnavailable(data.name, queryDef)
		}

		return LanguageLayerQueryCursor(query: query, tree: tree, set: set, depth: depth)
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
		// using set to filter out matches here doesn't actually work, because it is possible that a parent query match expansion will result in an intersection that otherwise would not happen

		try block(rootSnapshot)

		for sublayer in sublayerSnapshots {
			try sublayer.enumerateSnapshots(in: set, block: block)
		}
	}

	private func queryTargets(in set: IndexSet, for queryDef: Query.Definition) -> [LanguageTreeQueryCursor.Target] {
		var targets = [LanguageTreeQueryCursor.Target]()

		enumerateSnapshots(in: set) { snapshot in
			if let target = snapshot.queryTarget(for: queryDef) {
				targets.append(target)
			}
		}

		return targets
	}
}

extension LanguageLayerTreeSnapshot: Queryable {
	public func executeQuery(_ queryDef: Query.Definition, in set: IndexSet) throws -> LanguageTreeQueryCursor {
		let targets = queryTargets(in: set, for: queryDef)

		return LanguageTreeQueryCursor(set: set, targets: targets)
	}
}
