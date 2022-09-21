import Foundation
import tree_sitter

public struct Language {
    public var tsLanguage: UnsafePointer<TSLanguage>

    public init(language: UnsafePointer<TSLanguage>) {
        self.tsLanguage = language
    }
}

extension Language {
    public static var version: Int {
        return Int(TREE_SITTER_LANGUAGE_VERSION)
    }

    public static var minimumCompatibleVersion: Int {
        return Int(TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION)
    }

    public var ABIVersion: Int {
        return Int(ts_language_version(tsLanguage))
    }
    
    public var fieldCount: Int {
        return Int(ts_language_field_count(tsLanguage))
    }

    public var symbolCount: Int {
        return Int(ts_language_symbol_count(tsLanguage))
    }

    public func fieldName(for id: Int) -> String? {
        guard let str = ts_language_field_name_for_id(tsLanguage, TSFieldId(id)) else { return nil }
        
        return String(cString: str)
    }
    
    public func fieldId(for name: String) -> Int? {
        let count = UInt32(name.utf8.count)
        
        let value = name.withCString { cStr in
            return ts_language_field_id_for_name(tsLanguage, cStr, count)
        }
        
        return Int(value)
    }

    public func symbolName(for id: Int) -> String? {
        guard let str = ts_language_symbol_name(tsLanguage, TSSymbol(id)) else {
            return nil
        }

        return String(cString: str)
    }
}

#if !os(WASI)
public extension Language {
    /// Construct a query object from data in a file.
    func query(contentsOf url: URL) throws -> Query {
        let data = try Data(contentsOf: url)

        return try Query(language: self, data: data)
    }
}
#endif
