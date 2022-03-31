import Foundation

public final class ResolvingQueryCursor {
    public typealias TextProvider = (NSRange, Range<Point>) -> String?

    private var matches: [QueryMatch]
    private let cursor: QueryCursor
    private var index: Array.Index
    private var textProvider: TextProvider
    private var cachedText: [NSRange : String]

    public init(cursor: QueryCursor) {
        self.cursor = cursor
        self.matches = []
        self.index = matches.startIndex
        self.cachedText = [:]
        self.textProvider = { _, _ in return nil }
    }

    /// Eagerly load all `QueryMatch` objects.
    ///
    /// Iterating over matches can be very expensive for certain
    /// queries/inputs. This is helpful if you want to gather all
    /// matches in the background before evalucating them later on.
    public func prefetchMatches() {
        guard matches.isEmpty else {
            assertionFailure("Should not prefetch more than once")
            return
        }

        while let match = cursor.nextMatch() {
            matches.append(match)
        }

        self.index = matches.startIndex
    }

    public func prepare(with textProvider: @escaping TextProvider) {
        self.index = matches.startIndex
        self.cachedText.removeAll()

        // create a caching provider
        self.textProvider = { (range, pointRange) in
            if let value = self.cachedText[range] {
                return value
            }

            let value = textProvider(range, pointRange)

            self.cachedText[range] = value

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
            return cursor.nextMatch()
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
        switch predicate {
        case .eq(let strings, let names):
            return evaluateTextPredicate(match: match, captureNames: names, textProvider: textProvider) { text in
                return strings.allSatisfy({ $0 == text })
            }
        case .match(let exp, let names):
            return evaluateTextPredicate(match: match, captureNames: names, textProvider: textProvider) { text in
                let range = NSRange(0..<text.utf16.count)

                return exp.rangeOfFirstMatch(in: text, options: [], range: range).location != NSNotFound
            }
        case .isNot:
            return true
        case .generic:
            return false
        }
    }

    func evaluateTextPredicate(match: QueryMatch, captureNames: [String], textProvider: TextProvider, predicate: (String) -> Bool) -> Bool {
        for captureName in captureNames {
            let captures = match.captures(named: captureName)

            for capture in captures {
                let range = capture.node.range
                let pointRange = capture.node.pointRange

                guard let text = textProvider(range, pointRange) else {
                    return false
                }

                if predicate(text) == false {
                    return false
                }
            }
        }

        return true
    }
}
