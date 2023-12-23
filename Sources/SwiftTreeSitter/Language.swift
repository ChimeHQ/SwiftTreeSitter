import Foundation
import tree_sitter

public struct Language {
    /// This is a closure whose output URL is to the directory which has the language `scm` files.
    public typealias DirectoryProvider = () -> URL?

    public var tsLanguage: UnsafePointer<TSLanguage>
    public var directoryProvider: DirectoryProvider?

    /// Creates an instance.
    /// - Parameters:
    ///   - language: The TSLanguage instance to wrap.
    ///   - directoryProvider: An optional closure which would return a directory `URL` to the container of the
    ///   language's `scm` resources.
    public init(language: UnsafePointer<TSLanguage>, directoryProvider: DirectoryProvider? = nil) {
        self.tsLanguage = language
        self.directoryProvider = directoryProvider
    }

    #if !os(WASI)
    /// Creates an instance.
    /// - Parameters:
    ///   - language: The TSLanguage instance to wrap.
    ///   - bundle: The name of the language bundle.
	public init(language: UnsafePointer<TSLanguage>, bundle: String) {
		self.init(
			language: language,
			directoryProvider: {
				Language.bundledQueriesDirectory(named: bundle)
			}
		)
    }

	/// Creates an instance.
	///
	/// This assumes that the bundle follows the patter: "TreeSitter\(name)_TreeSitter\(name), which many do.
	/// - Parameters:
	///   - language: The TSLanguage instance to wrap.
	///   - name: The name of the language.
	public init(language: UnsafePointer<TSLanguage>, name: String) {
		self.init(
			language: language,
			directoryProvider: {
				Language.bundledQueriesDirectory(named: "TreeSitter\(name)_TreeSitter\(name)")
			}
		)
	}
    #endif
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
    public static func ==(lhs: Language, rhs: Language) -> Bool {
        return lhs.tsLanguage == rhs.tsLanguage
    }
}

extension Language {
	public var highlightsFileURL: URL? {
		return directoryProvider?()?.appendingPathComponent("highlights.scm")
	}

	public var injectionsFileURL: URL? {
		return directoryProvider?()?.appendingPathComponent("injections.scm")
	}
}

#if !os(WASI)
extension Language {
	static func bundledQueriesDirectory(named name: String) -> URL? {
		let embeddedBundleURL = effectiveBundle
			.resourceURL?
			.appendingPathComponent("\(name).bundle", isDirectory: true)

		guard let embeddedBundleURL else { return nil }

		return Bundle(url: embeddedBundleURL)?
			.resourceURL?
			.appendingPathComponent("queries", isDirectory: true)
    }

	private static var effectiveBundle: Bundle {
		let mainBundle = Bundle.main

		guard mainBundle.isXCTestRunner else {
			return mainBundle
		}

		let testBundle = Bundle.allBundles .first(where: {
			$0.bundlePath.components(separatedBy: "/").last?.contains("Tests.xctest") == true
		})

		return testBundle ?? mainBundle
	}
}

private extension Bundle {
	var isXCTestRunner: Bool {
#if DEBUG
		return NSClassFromString("XCTest") != nil
#else
		return false
#endif
	}
}

extension Language {
    /// Construct a query object from data in a file.
    public func query(contentsOf url: URL) throws -> Query {
        let data = try Data(contentsOf: url)

        return try Query(language: self, data: data)
    }
}
#endif
