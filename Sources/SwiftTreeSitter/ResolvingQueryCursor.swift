import Foundation

/// An enhanced QueryCursor that can resolve predicates.
///
/// By default tree-sitter leaves the evaluation of predicates up
/// to user libraries. `ResolvingQueryCursor` has a very similar API
/// to the standard `QueryCursor`, but can also resolve predicates. This class
/// also comes with some features that help to run queries in
/// the background safely and efficiently.
///
/// The following predicates are parsed and transformed into structured
/// `Predicate` cases. All others are turned into the `generic` case.
///
/// - `eq?`
/// - `not-eq?`
/// - `match?`
/// - `not-match?`
/// - `any-of?`
/// - `not-any-of?`
/// - `is-not?` (parsed, but not implemented)
/// - `set!` (handled by `QueryCursor`)
///
/// Here's an example of how it is used:
/// ```swift
/// let resolvingCursor = ResolvingQueryCursor(cursor: queryCursor)
///
/// let provider: TextProvider = { range, pointRange in ... }
///
/// resolvingCursor.prepare(with: provider)
///
/// for match in resolvingCursor {
///     print("match: ", match)
/// }
/// ```
public final class ResolvingQueryCursor {
	/// A function that can produce text content.
    public typealias TextProvider = (NSRange, Range<Point>) -> String?

    private var matches: [QueryMatch]
    private let cursor: QueryCursor
    private var index: Array.Index
    private(set) var textProvider: TextProvider

    public init(cursor: QueryCursor) {
        self.cursor = cursor
        self.matches = []
        self.index = matches.startIndex
        self.textProvider = { _, _ in return nil }
    }

    /// Eagerly load all `QueryMatch` objects.
    ///
    /// Iterating over matches can be very expensive for certain
    /// queries/inputs. This is helpful if you want to gather all
    /// matches in the background before evaluating them later on.
    public func prefetchMatches() {
        guard matches.isEmpty else {
            assertionFailure("Should not prefetch more than once")
            return
        }

        while let match = cursor.next() {
            matches.append(match)
        }

        self.index = matches.startIndex
    }

    public func prepare(with textProvider: @escaping TextProvider) {
        self.index = matches.startIndex

        var cachedText = [NSRange : String]()

        // create a caching provider
        self.textProvider = { (range, pointRange) in
            if let value = cachedText[range] {
                return value
            }

            let value = textProvider(range, pointRange)

            cachedText[range] = value

            return value
        }
    }
}

extension ResolvingQueryCursor: Sequence, IteratorProtocol {
    /// Get the next set of TextElement results
    ///
    /// If this cursor is evaluating a match with predicates,
    /// the parameters to the `prepare(textProvider:)` call will
    /// be applied. Otherwise, any results that require predicate
    /// evaluation will be dropped.
    public func next() -> QueryMatch? {
        while let match = nextMatch() {
            if evaluateMatch(match, textProvider: textProvider) == false {
                continue
            }

			return match
        }

        return nil
    }

    private func nextMatch() -> QueryMatch? {
        // use the cursor directly if we haven't prefetched
        if matches.isEmpty {
            return cursor.next()
        }

        if index >= matches.endIndex {
            return nil
        }

        let queryMatch = matches[index]

        index += 1

        return queryMatch
    }
}


extension ResolvingQueryCursor {
    func evaluateMatch(_ queryMatch: QueryMatch, textProvider: TextProvider) -> Bool {
        return queryMatch.predicates.allSatisfy({ evaluatePredicate($0, match: queryMatch, textProvider: textProvider) })
    }

    func evaluatePredicate(_ predicate: Predicate, match: QueryMatch, textProvider: TextProvider) -> Bool {
		for captureName in predicate.captureNames {
			let captures = match.captures(named: captureName)

			for capture in captures {
				let range = capture.node.range
				let pointRange = capture.node.pointRange

				guard let text = textProvider(range, pointRange) else {
					return false
				}

				if predicate.evalulate(with: text) == false {
					return false
				}
			}
		}

		return true
    }
}
