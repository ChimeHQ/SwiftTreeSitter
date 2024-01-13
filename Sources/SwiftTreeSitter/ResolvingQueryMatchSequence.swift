import Foundation

public struct ResolvingQueryMatchSequence<MatchSequence: Sequence> where MatchSequence.Element == QueryMatch {
	private let sequence: MatchSequence
	private var iterator: MatchSequence.Iterator
	private let context: Predicate.Context

	public init(sequence: MatchSequence, context: Predicate.Context) {
		self.sequence = sequence
		self.iterator = sequence.makeIterator()
		self.context = context.cachingContext
	}

	/// Interpret the sequence using the "injections.scm" definition
	public func injections() -> [NamedRange] {
		return compactMap({ $0.injection(with: context.textProvider) })
	}
}

extension ResolvingQueryMatchSequence: Sequence, IteratorProtocol {
	public mutating func next() -> QueryMatch? {
		while let match = iterator.next() {
			if match.allowed(in: context) == false {
				continue
			}

			return match
		}

		return nil
	}
}

extension Sequence where Element == QueryMatch {
	public func resolve(with context: Predicate.Context) -> ResolvingQueryMatchSequence<Self> {
		ResolvingQueryMatchSequence(sequence: self, context: context)
	}
}
