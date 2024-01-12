import Foundation

import SwiftTreeSitter
import enum SwiftTreeSitter.Predicate

public struct LanguageLayerQueryCursor {
	let baseCursor: QueryCursor
	let range: NSRange
	let name: String

	init(cursor: QueryCursor, range: NSRange, name: String) {
		self.baseCursor = cursor
		self.name = name
		self.range = range

		cursor.setRange(range)
	}
}

extension LanguageLayerQueryCursor: Sequence, IteratorProtocol {
	public typealias Element = QueryMatch

	public mutating func next() -> Element? {
		baseCursor.next()
	}
}

public struct LanguageTreeQueryCursor {
	private var subcursors: [LanguageLayerQueryCursor]

	init(subcursors: [LanguageLayerQueryCursor]) {
		self.subcursors = subcursors
	}

	mutating func merge(with other: LanguageTreeQueryCursor) {
		subcursors.append(contentsOf: other.subcursors)
	}
}

extension LanguageTreeQueryCursor: Sequence, IteratorProtocol {
	public typealias Element = QueryMatch

	public mutating func next() -> Element? {
		// this is not efficient
		for cursor in subcursors {
			if let match = cursor.baseCursor.next() {
				return match
			}
		}

		return nil
	}
}
