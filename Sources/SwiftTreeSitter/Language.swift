import Foundation
import tree_sitter

public struct Language {
    public var tsLanguage: UnsafePointer<TSLanguage>

    /// The topmost directory inside of the main bundle which will contain the scm resources for queries, highlights,
    /// etc. This does not need to be the precise name of a Swift package's resource bundle and is often the name
    /// of the Swift package vending resources (when used in a Swift Package Manager context).
    public var resourceDirectory: String?

    public init(language: UnsafePointer<TSLanguage>, resourceDirectory: String? = nil) {
        self.tsLanguage = language
        self.resourceDirectory = resourceDirectory
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

extension Language: Equatable {
}

public extension Language {
    var highlightsFileURL: URL? {
        return searchForResource(named: "highlights")
    }

    var injectionsFileURL: URL? {
        return searchForResource(named: "injections")
    }

    private func searchForResource(named name: String) -> URL? {
        let fileManager = FileManager.default
        var bundle = Bundle.main

        if bundle.isXCTestRunner {
            bundle = Bundle.allBundles
                .first(where: { $0.bundlePath.components(separatedBy: "/").last!.contains("Tests.xctest") == true })!
        }

        guard
            let resourceDirectory,
            let bundleURL = bundle.resourceURL,
            let foundBundleURL = try? fileManager
                .contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                .first(where: { $0.absoluteString.contains(resourceDirectory) })
        else { return nil }

        return foundBundleURL.appendingPathComponent("Contents/Resources/queries/\(name).scm")
    }
}

private extension Bundle {
    var isXCTestRunner: Bool {
        guard NSClassFromString("XCTest") != nil else { return false }
        return bundlePath.contains("/Developer/Library/Xcode/Agents")
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
