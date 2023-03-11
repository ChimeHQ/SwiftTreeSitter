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

public enum Predicate: Hashable, Sendable {
    case eq([String], captureNames: [String])
    case notEq([String], captureNames: [String])
    case match(NSRegularExpression, captureNames: [String])
    case notMatch(NSRegularExpression, captureNames: [String])
    case isNot(String)
    case anyOf(Set<String>, captureName: String)
    case notAnyOf(Set<String>, captureName: String)
	case set(captureName: String? = nil, key: String, value: String)
    case generic(String, strings: [String], captureNames: [String])

    public var captureNames: [String] {
        switch self {
        case .eq(_, let names):
            return names
        case .notEq(_, let names):
            return names
        case .match(_, let names):
            return names
        case .notMatch(_, let names):
            return names
        case .isNot:
            return []
        case .anyOf(_, let names):
            return [names]
        case .notAnyOf(_, let names):
            return [names]
		case .set:
			return []
        case .generic(_, _, let names):
            return names
        }
    }

    public func captures(in match: QueryMatch) -> [QueryCapture] {
        let names = captureNames

        return match.captures.filter({ capture in
            guard let name = capture.name else { return false }

            return names.contains(name)
        })
    }

	public func evalulate(with text: String) -> Bool {
		switch self {
		case .eq(let strings, _):
			return strings.allSatisfy({ $0 == text })
		case .notEq(let strings, _):
			return strings.allSatisfy({ $0 != text })
		case .match(let exp, _):
			let range = NSRange(0..<text.utf16.count)

			return exp.firstMatch(in: text, range: range) != nil
		case .notMatch(let exp, _):
			let range = NSRange(0..<text.utf16.count)

			return exp.firstMatch(in: text, range: range) == nil
		case .anyOf(let set, _):
			return set.contains(text)
		case .notAnyOf(let set, _):
			return set.contains(text) == false
		case .isNot:
			return false
		case .set:
			return true
		case .generic:
			return false
		}
	}
}

enum PredicateParserError: Error {
    case stepNameExpected
    case doneExpected
    case argumentsContainDone
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
        case "not-eq?":
            return .notEq(strings, captureNames: captures)
        case "match?":
            guard let pattern = strings.first else {
                return .generic(name, strings: strings, captureNames: captures)
            }

            let expression = try NSRegularExpression(pattern: pattern, options: [])

            return .match(expression, captureNames: captures)
        case "not-match?":
            guard let pattern = strings.first else {
                return .generic(name, strings: strings, captureNames: captures)
            }

            let expression = try NSRegularExpression(pattern: pattern, options: [])

            return .notMatch(expression, captureNames: captures)
        case "any-of?":
            guard let capture = captures.first else {
                return .generic(name, strings: strings, captureNames: captures)
            }

            return .anyOf(Set(strings), captureName: capture)
        case "not-any-of?":
            guard let capture = captures.first else {
                return .generic(name, strings: strings, captureNames: captures)
            }

            return .notAnyOf(Set(strings), captureName: capture)
        case "is-not?":
            if strings != ["local"] {
                return .generic(name, strings: strings, captureNames: captures)
            }

            return .isNot(strings.first!)
		case "set!":
			if strings.count != 2 || captures.count > 1 {
				return .generic(name, strings: strings, captureNames: captures)
			}

			return .set(captureName: captures.first, key: strings[0], value: strings[1])
        default:
            return .generic(name, strings: strings, captureNames: captures)
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
