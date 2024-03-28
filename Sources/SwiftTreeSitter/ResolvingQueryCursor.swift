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
/// - `is-not?`
/// - `set!`
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
@available(*, deprecated, message: "Please use ResolvingQueryMatchSequence")
public final class ResolvingQueryCursor {
	/// A function that can produce text content.
	public typealias TextProvider = Predicate.TextProvider

    private var matches: [QueryMatch]
    private let cursor: QueryCursor
    private var index: Array.Index
    private(set) var context: Predicate.Context

	public init(cursor: QueryCursor, context: Predicate.Context) {
        self.cursor = cursor
        self.matches = []
        self.index = matches.startIndex
		self.context = context.cachingContext
    }

	@MainActor
	public init(cursor: QueryCursor) {
		self.cursor = cursor
		self.matches = []
		self.index = matches.startIndex
		self.context = Predicate.Context.none
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

	/// Establish context for the cursor to evaluate matches.
	public func prepare(with provider: @escaping TextProvider) {
		let context = Predicate.Context(textProvider: provider,
										groupMembershipProvider: { _, _, _ in return false })

		self.prepare(with: context)
	}

	/// Establish context for the cursor to evaluate matches.
	public func prepare(with context: Predicate.Context) {
		self.index = matches.startIndex

		self.context = context.cachingContext
	}
}

@available(*, deprecated, message: "Please use ResolvingQueryMatchSequence")
extension ResolvingQueryCursor: Sequence, IteratorProtocol {
    /// Get the next set of TextElement results
    ///
    /// If this cursor is evaluating a match with predicates,
    /// the parameters to the `prepare(with:)` call will
    /// be applied. Otherwise, any results that require predicate
    /// evaluation will be incorrectly matched or skipped.
    public func next() -> QueryMatch? {
        while let match = nextMatch() {
			if match.allowed(in: context) == false {
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
