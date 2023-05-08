import Foundation

import SwiftTreeSitter

public enum LanguageLayerError: Error {
	case noRootNode
	case queryUnavailable(String, Query.Definition)
}

final class LanguageLayer {
	typealias Configuration = LanguageLayerTree.Configuration

	let languageConfig: LanguageConfiguration
	private let configuration: Configuration
	private let parser = Parser()
	private(set) var state = ParseState()
	private var sublayers = [LanguageLayer]()
	private(set) var rangeSet: IndexSet? = IndexSet()

	init(languageConfig: LanguageConfiguration, configuration: Configuration, ranges: [TSRange] = []) throws {
		self.languageConfig = languageConfig
		self.configuration = configuration

		try parser.setLanguage(languageConfig.language)

		if ranges.isEmpty == false {
			parser.includedRanges = ranges
		}

		invalidateRanges()
	}
}

extension LanguageLayer {
	private func invalidateRanges() {
		guard rangeSet != nil else { return }

		rangeSet = parser.incluedRangeSet
	}

	var spanningRange: NSRange? {
		return state.tree?.rootNode?.range
	}

	func contains(_ range: NSRange) -> Bool {
		guard let indexRange = Range(range) else { return false }

		if rangeSet?.contains(integersIn: indexRange) == true {
			return true
		}

		return spanningRange?.intersection(range)?.length != nil
	}

	func languageLayer(for range: NSRange) -> LanguageLayer? {
		guard contains(range) else {
			return nil
		}

		return sublayers.first(where: { $0.contains(range) }) ?? self
	}
}

extension LanguageLayer {
	func applyEdit(_ edit: InputEdit) {
		state.applyEdit(edit)

		invalidateRanges()

		sublayers.forEach({ $0.applyEdit(edit) })
	}

	func parse(with readHandler: Parser.ReadBlock, provider: LanguageLayerTree.TextProvider?) -> IndexSet {
		let newState = withoutActuallyEscaping(readHandler) { escapingClosure in
			parser.parse(state: state, readHandler: escapingClosure)
		}

		let oldState = state

		state = newState

		let set = oldState.changedSet(for: newState)

		invalidateSublayers(with: set, readHandler: readHandler, provider: provider)

		return set
	}
}

extension LanguageLayer {
	func executeShallowQuery(_ queryDef: Query.Definition, in range: NSRange) throws -> ResolvingQueryCursor {
		guard let query = languageConfig.queries[queryDef] else {
			let name = languageConfig.name

			throw LanguageLayerError.queryUnavailable(name, queryDef)
		}

		guard let node = state.tree?.rootNode else {
			throw LanguageLayerError.noRootNode
		}

		let cursor = query.execute(node: node, in: state.tree)

		cursor.setRange(range)

		return ResolvingQueryCursor(cursor: cursor)
	}

	private func executeRecursiveQuery(_ queryDef: Query.Definition, in set: IndexSet) throws -> [LayeredQueryCursor.NamedCursor] {
		let effectiveSet = rangeSet?.intersection(set) ?? set

		let namedCursors = try effectiveSet.rangeView
			.compactMap { NSRange($0) }
			.map { try executeShallowQuery(queryDef, in: $0) }
			.map { (languageConfig.name, $0) }

		let subCursors = try sublayers.flatMap { layer in
			try layer.executeRecursiveQuery(queryDef, in: set)
		}

		return namedCursors + subCursors
	}

	func executeQuery(_ queryDef: Query.Definition, in set: IndexSet) throws -> LayeredQueryCursor {
		let cursors = try executeRecursiveQuery(queryDef, in: set)

		return LayeredQueryCursor(cursors: cursors)
	}
}

extension LanguageLayer {
	func computeInjections(in set: IndexSet, provider: LanguageLayerTree.TextProvider?) -> [NamedRange] {
		return set.rangeView
			.compactMap { try? executeShallowQuery(.injections, in: NSRange($0)) }
			.flatMap { cursor in
				if let provider = provider {
					cursor.prepare(with: provider)
				}

				return cursor.injections()
			}
	}

	func buildSublayers(from injections: [NamedRange]) -> [LanguageLayer] {
		let groups = Dictionary(grouping: injections, by: { $0.name })

		return groups.compactMap { (name, namedRanges) -> LanguageLayer? in
			do {
				guard let subLang = configuration.languageProvider?(name) else {
					print("no injected language returned for \(name)")
					return nil
				}

				let ranges = namedRanges.map { $0.tsRange }

				return try LanguageLayer(languageConfig: subLang, configuration: configuration, ranges: ranges)
			} catch {
				print("failed to set injected language for \(name): \(error)")
				return nil
			}
		}
	}

	func invalidateSublayers(with invalidatedSet: IndexSet, readHandler: Parser.ReadBlock, provider: LanguageLayerTree.TextProvider?) {
		sublayers.removeAll { layer in
			guard let set = layer.rangeSet else { return true }

			return set.intersection(invalidatedSet).isEmpty == false
		}

		let injections = computeInjections(in: invalidatedSet, provider: provider)

		self.sublayers = buildSublayers(from: injections)

		sublayers.forEach { sublayer in
			let _ = sublayer.parse(with: readHandler, provider: provider)
		}
	}
}
