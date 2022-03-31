import Foundation
import tree_sitter

public enum QueryPredicateStep: Hashable {
    case done
    case capture(String)
    case string(String)
}

extension QueryPredicateStep: CustomStringConvertible {
    public var description: String {
        switch self {
        case .done:
            return "<done>"
        case .capture(let v):
            return "<capture: \(v)>"
        case .string(let v):
            return "<string: \(v)>"
        }
    }
}

public typealias PredicateTextProvider = (Range<UInt32>, Range<Point>) -> Result<String, Error>

public enum Predicate: Hashable {
    case eq([String], captureNames: [String])
    case match(NSRegularExpression, captureNames: [String])
    case isNot(String)

    public var captureNames: [String] {
        switch self {
        case .eq(_, let names):
            return names
        case .match(_, let names):
            return names
        case .isNot:
            return []
        }
    }

    public func captures(in match: QueryMatch) -> [QueryCapture] {
        let names = captureNames

        return match.captures.filter({ capture in
            guard let name = capture.name else { return false }

            return names.contains(name)
        })
    }

    func evaluate(with match: QueryMatch, textProvider: PredicateTextProvider) throws -> Bool {
        let captures = captures(in: match)

        switch self {
        case .eq(let strings, _):
            return try evaluateEq(strings: strings, captures: captures, textProvider: textProvider)
        case .match(let regex, _):
            return try evaluateMatch(regex: regex, captures: captures, textProvider: textProvider)
        case .isNot(_):
            return true
        }
    }

    private func evaluateEq(strings: [String], captures: [QueryCapture], textProvider: PredicateTextProvider) throws -> Bool {
        // find the length needed to match a string
        let neededLength = strings.map({ $0.utf16.count }).map { $0 * 2 }.first

        // compute the string contents for the captures
        let captureStrings = try captures.map { capture -> String in
            // this is an optimization to avoid querying for the string value
            // if we don't at least match the needed length
            if let length = neededLength, length != capture.node.byteRange.count {
                return ""
            }

            let result = textProvider(capture.node.byteRange, capture.node.pointRange)

            return try result.get()
        }

        // finally, make sure all of those things are the same
        let allStrings = strings + captureStrings

        return allStrings.dropFirst().allSatisfy({ $0 == strings.first })
    }

    private func evaluateMatch(regex: NSRegularExpression, captures: [QueryCapture], textProvider: PredicateTextProvider) throws -> Bool {
        // we must get the capture text contents
        let contents = try captures.map({ try textProvider($0.node.byteRange, $0.node.pointRange).get() })

        return contents.allSatisfy { content in
            let range = NSRange(location: 0, length: content.utf16.count)

            return regex.numberOfMatches(in: content, options: [], range: range) > 0
        }
    }
}

enum PredicateParserError: Error {
    case stepNameExpected
    case doneExpected
    case argumentsContainDone
    case unsupportedPredicate(String)
    case unsupportedMatchArguments
    case unsupportedIsNotArguments([String])
}

struct PredicateParser {
    func parse(_ steps: [QueryPredicateStep]) throws -> [Predicate] {
        var predicates = [Predicate]()

        var stepList = steps
        while stepList.isEmpty == false {
            let (predicate, count) = try parseNextPredicate(stepList)

            predicates.append(predicate)

            stepList.removeFirst(count)
        }

        return predicates
    }

    func parseNextPredicate(_ steps: [QueryPredicateStep]) throws -> (Predicate, Int) {
        guard case .string(let name)? = steps.first else {
            throw PredicateParserError.stepNameExpected
        }

        guard let doneIndex = steps.firstIndex(of: .done) else {
            throw PredicateParserError.doneExpected
        }

        let args = Array(steps[1..<doneIndex])
        let predicate = try buildPredicate(with: name, argSteps: args)

        // we want to remoe the done itself too

        return (predicate, doneIndex + 1)
    }

    private func buildPredicate(with name: String, argSteps: [QueryPredicateStep]) throws -> Predicate {
        var strings = [String]()
        var captures = [String]()

        for arg in argSteps {
            switch arg {
            case .capture(let value):
                captures.append(value)
            case .string(let value):
                strings.append(value)
            case .done:
                throw PredicateParserError.argumentsContainDone
            }
        }

        switch name {
        case "eq?":
            return .eq(strings, captureNames: captures)
        case "match?":
            if strings.count != 1 {
                throw PredicateParserError.unsupportedMatchArguments
            }

            let expression = try NSRegularExpression(pattern: strings.first!, options: [])

            return .match(expression, captureNames: captures)
        case "is-not?":
            if strings != ["local"] {
                throw PredicateParserError.unsupportedIsNotArguments(strings)
            }

            return .isNot(strings.first!)
        default:
            throw PredicateParserError.unsupportedPredicate(name)
        }
    }
}

extension PredicateParser {
    func predicates(in query: OpaquePointer) throws -> [[Predicate]] {
        let patternCount = Int(ts_query_pattern_count(query))

        var predicates = [[Predicate]](repeating: [], count: patternCount)

        for i in 0..<patternCount {
            let steps = try predicateSteps(for: i, in: query)
            let subpredicates = try parse(steps)

            if subpredicates.isEmpty == false {
                predicates[i] = subpredicates
            }
        }

        return predicates
    }

    func predicateSteps(for index: Int, in query: OpaquePointer) throws -> [QueryPredicateStep] {
        var length: UInt32 = 0

        let steps = ts_query_predicates_for_pattern(query, UInt32(index), &length)

        let buffer = UnsafeBufferPointer<TSQueryPredicateStep>(start: steps,
                                                                count: Int(length))

        return try buffer.map { step -> QueryPredicateStep in
            let valueId = step.value_id
            var length: UInt32 = 0

            switch step.type {
            case TSQueryPredicateStepTypeCapture:
                guard let cStr = ts_query_capture_name_for_id(query, valueId, &length) else {
                    throw QueryPredicateError.valueNotFound
                }

                return .capture(String(cString: cStr))
            case TSQueryPredicateStepTypeString:
                guard let cStr = ts_query_string_value_for_id(query, valueId, &length) else {
                    throw QueryPredicateError.valueNotFound
                }

                return .string(String(cString: cStr))
            case TSQueryPredicateStepTypeDone:
                return .done
            default:
                throw QueryPredicateError.unrecognizedStepType
            }
        }
    }
}
