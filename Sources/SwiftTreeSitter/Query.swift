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

public class Query {
    let internalQuery: OpaquePointer

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

        guard let result = result else {
            throw QueryError(offset: errorOffset, internalError: queryError)
        }

        self.internalQuery = result
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
}

public struct QueryCapture {
    public var node: Node
    public var index: Int

    init?(tsCapture: TSQueryCapture) {
        guard let node = Node(internalNode: tsCapture.node) else {
            return nil
        }

        self.node = node
        self.index = Int(tsCapture.index)
    }
}

public struct QueryMatch {
    public var id: Int
    public var patternIndex: Int
    public var captures: [QueryCapture]
}

public class QueryCursor {
    let internalCursor: OpaquePointer

    public init() {
        self.internalCursor = ts_query_cursor_new()
    }

    deinit {
        ts_query_cursor_delete(internalCursor)
    }

    public func execute(query: Query, node: Node) {
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

    public func nextMatch() -> QueryMatch? {
        var match = TSQueryMatch(id: 0, pattern_index: 0, capture_count: 0, captures: nil)

        if ts_query_cursor_next_match(internalCursor, &match) == false {
            return nil
        }

        let captureBuffer = UnsafeBufferPointer<TSQueryCapture>(start: match.captures,
                                                                count: Int(match.capture_count))

        let captures = captureBuffer.compactMap({ QueryCapture(tsCapture: $0) })

        return QueryMatch(id: Int(match.id),
                          patternIndex: Int(match.pattern_index),
                          captures: captures)
    }

    public func nextCapture() -> QueryCapture? {
        var match = TSQueryMatch(id: 0, pattern_index: 0, capture_count: 0, captures: nil)
        var index: UInt32 = 0

        if ts_query_cursor_next_capture(internalCursor, &match, &index) == false {
            return nil
        }

        let captureBuffer = UnsafeBufferPointer<TSQueryCapture>(start: match.captures,
                                                                count: Int(match.capture_count))

        return QueryCapture(tsCapture: captureBuffer[Int(index)])
    }
}
