//
//  Language.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-18.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter
import tree_sitter_go

public enum Language {
    case go
}

extension Language {
    public static var version: Int {
        return Int(TREE_SITTER_LANGUAGE_VERSION)
    }

    public static var minimumCompatibleVersion: Int {
        return Int(TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION)
    }

    var internalLanguage: UnsafePointer<TSLanguage>? {
        switch self {
        case .go:
            return UnsafePointer(tree_sitter_go())
        }
    }

    public var ABIVersion: Int {
        guard let lang = internalLanguage else { return 0 }

        return Int(ts_language_version(lang))
    }
    
    public var fieldCount: Int {
        guard let lang = internalLanguage else { return 0 }
        
        return Int(ts_language_field_count(lang))
    }

    public var symbolCount: Int {
        guard let lang = internalLanguage else { return 0 }

        return Int(ts_language_symbol_count(lang))
    }

    public func fieldName(for id: Int) -> String? {
        guard let lang = internalLanguage else { return nil }
        guard let str = ts_language_field_name_for_id(lang, TSFieldId(id)) else { return nil }
        
        return String(cString: str)
    }
    
    public func fieldId(for name: String) -> Int? {
        guard let lang = internalLanguage else { return nil }
        
        let count = UInt32(name.utf8.count)
        
        let value = name.withCString { cStr in
            return ts_language_field_id_for_name(lang, cStr, count)
        }
        
        return Int(value)
    }

    public func symbolName(for id: Int) -> String? {
        guard let str = ts_language_symbol_name(internalLanguage, TSSymbol(id)) else {
            return nil
        }

        return String(cString: str)
    }
}
