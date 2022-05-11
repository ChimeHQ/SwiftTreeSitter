import XCTest
@testable import SwiftTreeSitter

final class PredicateTests: XCTestCase {
    func testParseEqTwoArgs() throws {
        let steps: [QueryPredicateStep] = [
            .string("eq?"),
            .capture("@a"),
            .string("thing"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.eq(["thing"], captureNames: ["@a"]),
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseEqFourArgs() throws {
        let steps: [QueryPredicateStep] = [
            .string("eq?"),
            .capture("@a"),
            .capture("@b"),
            .capture("@c"),
            .capture("@d"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.eq([], captureNames: ["@a", "@b", "@c", "@d"]),
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseTwoEqTwoArgs() throws {
        let steps: [QueryPredicateStep] = [
            .string("eq?"),
            .capture("@a"),
            .string("thing"),
            .done,
            .string("eq?"),
            .capture("@b"),
            .string("thing"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.eq(["thing"], captureNames: ["@a"]),
            Predicate.eq(["thing"], captureNames: ["@b"]),
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseNotEq() throws {
        let steps: [QueryPredicateStep] = [
            .string("not-eq?"),
            .capture("@a"),
            .string("thing"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.notEq(["thing"], captureNames: ["@a"]),
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseMatch() throws {
        let steps: [QueryPredicateStep] = [
            .string("match?"),
            .capture("@a"),
            .string("^(a|b|c)$"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.match(try NSRegularExpression(pattern: "^(a|b|c)$", options: []), captureNames: ["@a"])
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseNotMatch() throws {
        let steps: [QueryPredicateStep] = [
            .string("not-match?"),
            .capture("@a"),
            .string("^(a|b|c)$"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.notMatch(try NSRegularExpression(pattern: "^(a|b|c)$", options: []), captureNames: ["@a"])
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseIsNotLocal() throws {
        let steps: [QueryPredicateStep] = [
            .string("is-not?"),
            .string("local"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.isNot("local")
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseAnyOf() throws {
        let steps: [QueryPredicateStep] = [
            .string("any-of?"),
            .capture("@a"),
            .string("foo"),
            .string("bar"),
            .string("baz"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.anyOf(Set(["foo", "bar", "baz"]), captureName: "@a"),
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseNotAnyOf() throws {
        let steps: [QueryPredicateStep] = [
            .string("not-any-of?"),
            .capture("@a"),
            .string("foo"),
            .string("bar"),
            .string("baz"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.notAnyOf(Set(["foo", "bar", "baz"]), captureName: "@a"),
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }

    func testParseUnknown() throws {
        let steps: [QueryPredicateStep] = [
            .string("foo?"),
            .string("a"),
            .capture("@b"),
            .capture("@c"),
            .done
        ]

        let predicates = try PredicateParser().parse(steps)

        let expectedPredicates = [
            Predicate.generic("foo?", strings: ["a"], captureNames: ["@b", "@c"])
        ]

        XCTAssertEqual(predicates, expectedPredicates)
    }
}
