import Foundation

import SwiftTreeSitter
import enum SwiftTreeSitter.Predicate

public struct LayeredQueryCursor {
	public typealias NamedCursor = (String, ResolvingQueryCursor)

	private var cursors: [NamedCursor]

	public init(cursors: [NamedCursor]) {
		self.cursors = cursors
	}
}

extension LayeredQueryCursor: Sequence, IteratorProtocol {
	public typealias Element = (String, QueryMatch)

	public mutating func next() -> Element? {
		for namedCursor in cursors {
			if let match = namedCursor.1.next() {
				return (namedCursor.0, match)
			}
		}

		return nil
	}
}

extension LayeredQueryCursor {
	public func prepare(with textProvider: @escaping ResolvingQueryCursor.TextProvider) {
		cursors.forEach { $0.1.prepare(with: textProvider) }
	}

	public func prepare(with context: Predicate.Context) {
		cursors.forEach { $0.1.prepare(with: context) }
	}

	public func highlights() -> [NamedRange] {
		return map({ $0.1.captures })
			.flatMap({ $0 })
			.sorted()
			.compactMap { $0.highlight }
	}

	public func locals() -> [NamedRange] {
		return map({ $0.1.captures })
			.flatMap({ $0 })
			.compactMap { $0.locals }
	}
}
