import Foundation
import tree_sitter

enum ParserError: Error {
    case languageIncompatible
    case languageFailure
    case languageInvalid
    case unsupportedEncoding(String.Encoding)
}

public class Parser {
    private let internalParser: OpaquePointer
    private let encoding: String.Encoding

    public init() {
        self.internalParser = ts_parser_new()
        self.encoding = String.nativeUTF16Encoding
    }

    deinit {
        ts_parser_delete(internalParser)
    }
}

extension Parser {
    public func setLanguage(_ language: Language) throws {
        try setLanguage(language.tsLanguage)
    }

    public func setLanguage(_ language: UnsafePointer<TSLanguage>) throws {
        let success = ts_parser_set_language(internalParser, language)

        if success == false {
            throw ParserError.languageFailure
        }
    }
}

extension Parser {
    public typealias ReadBlock = (Int, Point) -> Data?

    public func parse(_ string: String) -> Tree? {
        guard let data = string.data(using: encoding) else { return nil }

        let dataLength = data.count

        let optionalTreePtr = data.withUnsafeBytes({ (byteBuffer) -> OpaquePointer? in
            guard let ptr = byteBuffer.baseAddress?.bindMemory(to: Int8.self, capacity: dataLength) else {
                return nil
            }

            return ts_parser_parse_string_encoding(internalParser, nil, ptr, UInt32(dataLength), TSInputEncodingUTF16)
        })

        return optionalTreePtr.flatMap({ Tree(internalTree: $0) })
    }

    public func parse(tree: Tree?, readBlock: @escaping ReadBlock) -> Tree? {
        let input = Input(encoding: TSInputEncodingUTF16, readBlock: readBlock)

        guard let internalInput = input.internalInput else {
            return nil
        }

        guard let newTree = ts_parser_parse(internalParser, tree?.internalTree, internalInput) else {
            return nil
        }

        return Tree(internalTree: newTree)
    }

    public func parse(tree: Tree?, string: String, limit: Int? = nil, chunkSize: Int = 2048) -> Tree? {
        let usableLimit = limit ?? string.utf16.count
        let encoding = self.encoding

        return parse(tree: tree) { (start, _) -> Data? in
            return string.data(at: start,
                               limit: usableLimit,
                               using: encoding,
                               chunkSize: chunkSize)
        }
    }
}
