import Foundation

import SwiftTreeSitter

public enum LanguageLayerError: Error {
	case noRootNode
	case queryUnavailable(String, Query.Definition)
}

public final class LanguageLayer {
	public typealias LanguageProvider = (String) -> LanguageConfiguration?

	public struct Content {
		public let readHandler: Parser.ReadBlock
		public let textProvider: SwiftTreeSitter.Predicate.TextProvider

		public init(
			readHandler: @escaping Parser.ReadBlock,
			textProvider: @escaping SwiftTreeSitter.Predicate.TextProvider
		) {
			self.readHandler = readHandler
			self.textProvider = textProvider
		}

		public init(string: String) {
			let read = Parser.readFunction(for: string, limit: string.utf16.count)

			self.init(
				readHandler: read,
				textProvider: string.cursorTextProvider
			)
		}
	}

	public struct Configuration {
		public let languageProvider: LanguageProvider

		public init(
			languageProvider: @escaping LanguageProvider = { _ in nil }
		) {
			self.languageProvider = languageProvider
		}
	}

	public let languageConfig: LanguageConfiguration
	private let configuration: Configuration
	private let parser = Parser()
	private(set) var state = ParseState()
	private var sublayers = [LanguageLayer]()
	private(set) var rangeSet: IndexSet? = IndexSet()
	private var missingInjections = [String: [NamedRange]]()

	init(languageConfig: LanguageConfiguration, configuration: Configuration, ranges: [TSRange]) throws {
		self.languageConfig = languageConfig
		self.configuration = configuration

		try parser.setLanguage(languageConfig.language)

		if ranges.isEmpty == false {
			parser.includedRanges = ranges
		}

		invalidateRanges()
	}

	public convenience init(languageConfig: LanguageConfiguration, configuration: Configuration) throws {
		try self.init(languageConfig: languageConfig, configuration: configuration, ranges: [])
	}

	public var languageName: String {
		languageConfig.name
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

	func parse(with content: Content) -> IndexSet {
		let newState = withoutActuallyEscaping(content.readHandler) { escapingClosure in
			parser.parse(state: state, readHandler: escapingClosure)
		}

		let oldState = state

		state = newState

		let set = oldState.changedSet(for: newState)

		try? invalidateSublayers(with: set, content: content)

		return set
	}

	@discardableResult
	public func replaceContent(with string: String, transformer: Point.LocationTransformer = { _ in nil }) -> IndexSet {
		let fullRange = spanningRange ?? NSRange(0..<0)
		let delta = string.utf16.count - fullRange.length
		let edit = InputEdit(
			range: fullRange,
			delta: delta,
			oldEndPoint: transformer(fullRange.length) ?? .zero,
			transformer: transformer
		)

		let content = LanguageLayer.Content(string: string)

		return didChangeContent(using: edit, content: content)
	}

	public func didChangeContent(using edit: InputEdit, content: LanguageLayer.Content) -> IndexSet {
		applyEdit(edit)

		return parse(with: content)
	}

	public func languageConfigurationChanged(for name: String, content: Content) throws -> IndexSet {
		let normalizedName = name.lowercased()

		if languageName == normalizedName {
			self.state = ParseState()

			return parse(with: content)
		}

		var invalidated = IndexSet()

		for sublayer in sublayers {
			let subset = try sublayer.languageConfigurationChanged(for: normalizedName, content: content)

			invalidated.formUnion(subset)
		}

		if let missing = missingInjections[normalizedName] {
			let sublang = configuration.languageProvider(normalizedName)!
			let ranges = missing.map { $0.tsRange }
			let sublayer = try LanguageLayer(languageConfig: sublang, configuration: configuration, ranges: ranges)

			sublayers.append(sublayer)

			let subset = sublayer.parse(with: content)

			invalidated.formUnion(subset)

			missingInjections[normalizedName] = nil
		}

		return invalidated
	}
}

extension LanguageLayer {
	func enumerateLanguageLayers(in set: IndexSet, block: (LanguageLayer) throws -> Void) rethrows {
		let effectiveSet = rangeSet?.intersection(set) ?? set

		if effectiveSet.isEmpty {
			return
		}

		try block(self)

		for layer in sublayers {
			try layer.enumerateLanguageLayers(in: effectiveSet, block: block)
		}
	}

	public func snapshot(in set: IndexSet? = nil) -> LanguageLayerTreeSnapshot? {
		guard let rootSnapshot = LanguageLayerSnapshot(languageLayer: self) else {
			return nil
		}

		let subSnapshots = sublayers.compactMap { $0.snapshot(in: set) }

		if subSnapshots.count != sublayers.count {
			return nil
		}

		return LanguageLayerTreeSnapshot(rootSnapshot: rootSnapshot, sublayerSnapshots: subSnapshots)
	}
}

extension LanguageLayer: Queryable {
	private func executeShallowQuery(_ queryDef: Query.Definition, in range: NSRange) throws -> LanguageLayerQueryCursor {
		let name = languageConfig.name

		guard let query = languageConfig.queries[queryDef] else {
			throw LanguageLayerError.queryUnavailable(name, queryDef)
		}

		guard let tree = state.tree else {
			throw LanguageLayerError.noRootNode
		}

		let cursor = query.execute(in: tree)

		return LanguageLayerQueryCursor(cursor: cursor, range: range, name: name)
	}

	public func executeQuery(_ queryDef: Query.Definition, in set: IndexSet) throws -> LanguageTreeQueryCursor {
		let effectiveSet = rangeSet?.intersection(set) ?? set

		let layeredCursors = try effectiveSet.rangeView
			.compactMap { NSRange($0) }
			.map { try executeShallowQuery(queryDef, in: $0) }

		var treeQueryCursor = LanguageTreeQueryCursor(subcursors: layeredCursors)

		for layer in sublayers {
			let subcursor = try layer.executeQuery(queryDef, in: set)

			treeQueryCursor.merge(with: subcursor)
		}

		return treeQueryCursor
	}
}

extension LanguageLayer {
	private func buildSublayers(from injections: [NamedRange]) -> [LanguageLayer] {
		let groups = Dictionary(grouping: injections, by: { $0.name })

		return groups.compactMap { (name, namedRanges) -> LanguageLayer? in
			do {
				guard let subLang = configuration.languageProvider(name) else {
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

	func invalidateSublayers(with invalidatedSet: IndexSet, content: Content) throws {
		sublayers.removeAll { layer in
			guard let set = layer.rangeSet else { return true }

			return set.intersection(invalidatedSet).isEmpty == false
		}

		let injections = try injections(in: invalidatedSet, provider: content.textProvider)

		self.sublayers = buildSublayers(from: injections)

		let createdNames = Set(sublayers.map { $0.languageName })
		let groups = Dictionary(grouping: injections.filter { createdNames.contains($0.name) == false }, by: { $0.name })
		self.missingInjections = groups

		for sublayer in sublayers {
			let _ = sublayer.parse(with: content)
		}
	}
}
