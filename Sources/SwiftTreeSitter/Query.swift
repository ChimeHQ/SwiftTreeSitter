import Foundation
import tree_sitter

public enum QueryError: Error {
    case none
    case syntax(UInt32)
    case nodeType(UInt32)
    case field(UInt32)
    case capture(UInt32)
    case structure(UInt32)
    case unknown(UInt32)

    init(offset: UInt32, internalError: TSQueryError) {
        switch internalError {
        case TSQueryErrorNone:
            self = .none
        case TSQueryErrorSyntax:
            self = .syntax(offset)
        case TSQueryErrorNodeType:
            self = .nodeType(offset)
        case TSQueryErrorField:
            self = .field(offset)
        case TSQueryErrorCapture:
            self = .capture(offset)
        case TSQueryErrorStructure:
            self = .structure(offset)
        default:
            self = .unknown(offset)
        }
    }
}

public enum QueryPredicateError: Error {
    case valueNotFound
    case unrecognizedStepType
    case queryInvalid
    case textContentUnavailable
}

public class Query {
    let internalQuery: OpaquePointer
    let predicateList: [[Predicate]]

    /// Construct a query object from scm data
    ///
    /// This operation has do to a lot of work, especially if any
    /// patterns contain predicates. You should expect it will
    /// be expensive.
    public init(language: Language, data: Data) throws {
        let dataLength = data.count
        var errorOffset: UInt32 = 0
        var queryError: TSQueryError = TSQueryErrorNone

        let result = data.withUnsafeBytes { byteBuffer -> OpaquePointer? in
            guard let ptr = byteBuffer.baseAddress?.bindMemory(to: CChar.self, capacity: dataLength) else {
                return nil
            }

            return ts_query_new(language.tsLanguage,
                                ptr, UInt32(dataLength),
                                &errorOffset,
                                &queryError)
        }

        guard let queryPtr = result else {
            throw QueryError(offset: errorOffset, internalError: queryError)
        }

        self.internalQuery = queryPtr
        self.predicateList = try PredicateParser().predicates(in: queryPtr)
    }

    deinit {
        ts_query_delete(internalQuery)
    }

    public var patternCount: Int {
        return Int(ts_query_pattern_count(internalQuery))
    }

    public var captureCount: Int {
        return Int(ts_query_capture_count(internalQuery))
    }

    public var stringCount: Int {
        return Int(ts_query_string_count(internalQuery))
    }

    public func execute(node: Node) -> QueryCursor {
        let cursor = QueryCursor()

        cursor.execute(query: self, node: node)

        return cursor
    }

    public func captureName(for id: Int) -> String? {
        var length: UInt32 = 0

        guard let cStr = ts_query_capture_name_for_id(internalQuery, UInt32(id), &length) else {
            return nil
        }

        return String(cString: cStr)
    }

    public func stringName(for id: Int) -> String? {
        var length: UInt32 = 0

        guard let cStr = ts_query_string_value_for_id(internalQuery, UInt32(id), &length) else {
            return nil
        }

        return String(cString: cStr)
    }

    public func predicates(for patternIndex: Int) -> [Predicate] {
        return predicateList[patternIndex]
    }

    public var hasPredicates: Bool {
        for i in 0..<patternCount {
            if predicates(for: i).isEmpty == false {
                return true
            }
        }

        return false
    }
}

public struct QueryCapture {
    public var node: Node
    public var index: Int
    public var name: String?

    init?(tsCapture: TSQueryCapture, name: String?) {
        guard let node = Node(internalNode: tsCapture.node) else {
            return nil
        }

        self.node = node
        self.index = Int(tsCapture.index)
        self.name = name
    }
}

public struct QueryMatch {
    public var id: Int
    public var patternIndex: Int
    public var captures: [QueryCapture]
    public let predicates: [Predicate]

    public func captures(named name: String) -> [QueryCapture] {
        return captures.filter({ $0.name == name })
    }
}

public class QueryCursor {
    let internalCursor: OpaquePointer
    public private(set) var activeQuery: Query?

    public init() {
        self.internalCursor = ts_query_cursor_new()
    }

    deinit {
        ts_query_cursor_delete(internalCursor)
    }

    public func execute(query: Query, node: Node) {
        self.activeQuery = query

        ts_query_cursor_exec(internalCursor, query.internalQuery, node.internalNode)
    }

    public var matchLimit: Int {
        get {
            Int(ts_query_cursor_match_limit(internalCursor))
        }
        set {
            ts_query_cursor_set_match_limit(internalCursor, UInt32(newValue))
        }
    }

    public func setByteRange(range: Range<UInt32>) {
        ts_query_cursor_set_byte_range(internalCursor, range.lowerBound, range.upperBound)
    }

    public func setPointRange(range: Range<Point>) {
        let start = range.lowerBound.internalPoint
        let end = range.upperBound.internalPoint

        ts_query_cursor_set_point_range(internalCursor, start, end)
    }

    func makeCapture(from capture: TSQueryCapture) -> QueryCapture? {
        let name = activeQuery?.captureName(for: Int(capture.index))

        return QueryCapture(tsCapture: capture, name: name)
    }

    public func nextMatch() -> QueryMatch? {
        var match = TSQueryMatch(id: 0, pattern_index: 0, capture_count: 0, captures: nil)

        if ts_query_cursor_next_match(internalCursor, &match) == false {
            return nil
        }

        let captureBuffer = UnsafeBufferPointer<TSQueryCapture>(start: match.captures,
                                                                count: Int(match.capture_count))

        let patternIndex = Int(match.pattern_index)
        let predicates = activeQuery?.predicates(for: patternIndex) ?? []

        let captures = captureBuffer.compactMap({ makeCapture(from: $0) })

        return QueryMatch(id: Int(match.id),
                          patternIndex: Int(match.pattern_index),
                          captures: captures,
                          predicates: predicates)
    }

    public func nextCapture() -> QueryCapture? {
        var match = TSQueryMatch(id: 0, pattern_index: 0, capture_count: 0, captures: nil)
        var index: UInt32 = 0

        if ts_query_cursor_next_capture(internalCursor, &match, &index) == false {
            return nil
        }

        let captureBuffer = UnsafeBufferPointer<TSQueryCapture>(start: match.captures,
                                                                count: Int(match.capture_count))

        let capture = captureBuffer[Int(index)]

        return makeCapture(from: capture)
    }
}
