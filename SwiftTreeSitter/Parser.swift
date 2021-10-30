//
//  Parser.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-17.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter

enum ParserError: Error {
    case LanguageIncompatible
    case LanguageFailure
}

public class Parser {
    private let internalParser: OpaquePointer

    public init() {
        self.internalParser = ts_parser_new()
    }

    deinit {
        ts_parser_delete(internalParser)
    }
}

extension Parser {
    public func setLanguage(_ language: Language) throws {
        let success: Bool

        switch language {
        case .go:
            success = ts_parser_set_language(internalParser, language.internalLanguage)
        }

        if success == false {
            throw ParserError.LanguageFailure
        }
    }
}

extension Parser {
    public typealias ReadBlock = (Int, Point) -> Data?

    public func parse(_ string: String) -> Tree? {
        guard let data = string.data(using: .utf16) else {
            return nil
        }

        let bomRemovedData = data.suffix(from: 2)

        let dataLength = bomRemovedData.count

        let optionalTreePtr = bomRemovedData.withUnsafeBytes({ (byteBuffer) -> OpaquePointer? in
            guard let ptr = byteBuffer.baseAddress?.bindMemory(to: Int8.self, capacity: dataLength) else {
                return nil
            }

            return ts_parser_parse_string_encoding(internalParser, nil, ptr, UInt32(dataLength), TSInputEncodingUTF16)
        })

        return optionalTreePtr.flatMap({ Tree(internalTree: $0) })
    }

    public func parse(tree: Tree?, encoding: String.Encoding, readBlock: @escaping ReadBlock) -> Tree? {
        let input = Input(encoding: encoding, readBlock: readBlock)

        guard let internalInput = input.internalInput else {
            return nil
        }

        guard let newTree = ts_parser_parse(internalParser, tree?.internalTree, internalInput) else {
            return nil
        }

        return Tree(internalTree: newTree)
    }
}
