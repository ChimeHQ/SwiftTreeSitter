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
        guard let lang = internalLanguage else { return  0 }

        return Int(ts_language_version(lang))
    }
}
