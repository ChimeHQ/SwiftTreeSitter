import Foundation

import SwiftTreeSitter

public enum LanguageLayerError: Error {
	case rangeOutOfBounds(IndexSet, NSRange)
}

final class LanguageLayer {
	public typealias TextProvider = ResolvingQueryCursor.TextProvider

	enum Failure: Error {
		case noRootNode
		case outsideBounds(NSRange, [NSRange])
	}

	let language: Language
	private let parser = Parser()
	private(set) var state = ParseState()
	private var sublayers = [LanguageLayer]()
	private(set) var rangeSet = IndexSet()

	init(language: Language, ranges: [TSRange] = []) throws {
		self.language = language

		try parser.setLanguage(language)

		if ranges.isEmpty == false {
			parser.includedRanges = ranges
		}
	}
}

extension LanguageLayer {
	private func invalidateRanges() {
		rangeSet.removeAll()

		for tsRange in parser.includedRanges {
			guard let range = Range(tsRange.bytes.range) else { continue }

			rangeSet.insert(integersIn: range)
		}
	}

	var spanningRange: NSRange? {
		guard let lower = rangeSet.min() else { return nil }
		guard let upper = rangeSet.max() else { return nil }

		return NSRange(lower..<upper)
	}

	func contains(_ nsRange: NSRange) -> Bool {
		guard let range = Range(nsRange) else { return false }

		return rangeSet.contains(integersIn: range)
	}
}

extension LanguageLayer {
	func applyEdit(_ edit: InputEdit) {
		state.applyEdit(edit)

		invalidateRanges()

		sublayers.forEach({ $0.applyEdit(edit) })
	}

	func parse(with readHandler: Parser.ReadBlock) -> IndexSet {
		let newState = withoutActuallyEscaping(readHandler) { escapingClosure in
			parser.parse(state: state, readHandler: escapingClosure)
		}

		let oldState = state

		state = newState

		let set = oldState.changedSet(for: newState)

		invalidateSublayers(with: set)

		return set
	}
}

extension LanguageLayer {
	func executeQuery(_ query: Query, in range: NSRange) throws -> ResolvingQueryCursor {
		guard contains(range) else {
			throw LanguageLayerError.rangeOutOfBounds(rangeSet, range)
		}

		let cursor = try state.executeQuery(query)

		cursor.setRange(range)

		return ResolvingQueryCursor(cursor: cursor)
	}
}

extension LanguageLayer {
	func invalidateSublayers(with invalidatedSet: IndexSet) {
		sublayers.removeAll { layer in
			return layer.rangeSet.intersection(invalidatedSet).isEmpty == false
		}
	}
}
