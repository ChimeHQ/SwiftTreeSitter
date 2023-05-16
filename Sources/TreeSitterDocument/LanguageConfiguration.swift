import Foundation
import SwiftTreeSitter
import tree_sitter

public struct LanguageConfiguration {
	public let language: Language
	public let name: String
	public let queries: [Query.Definition: Query]

	public init(language: Language, name: String, queries: [Query.Definition: Query]) {
		self.language = language
		self.name = name
		self.queries = queries
	}
}

#if !os(WASI)
extension LanguageConfiguration {
	public init(language: Language, name: String) throws {
		let bundleName = "TreeSitter\(name)_TreeSitter\(name)"

		try self.init(language: language, name: name, bundleName: bundleName)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String) throws {
		try self.init(language: Language(language: tsLanguage), name: name)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String, queries: [Query.Definition: Query]) {
		self.init(language: Language(language: tsLanguage), name: name, queries: queries)
	}

	public init(language: Language, name: String, bundleName: String) throws {
		var queries: [Query.Definition: Query] = [:]

		if let query = try Self.query(for: .injections, bundleName: bundleName, for: language) {
			queries[.injections] = query
		}

		if let query = try Self.query(for: .highlights, bundleName: bundleName, for: language) {
			queries[.highlights] = query
		}

		if let query = try Self.query(for: .locals, bundleName: bundleName, for: language) {
			queries[.locals] = query
		}

		self.init(language: language, name: name, queries: queries)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String, bundleName: String) throws {
		try self.init(language: Language(language: tsLanguage), name: name, bundleName: bundleName)
	}

	static var effectiveBundle: Bundle = {
		let mainBundle = Bundle.main

		guard mainBundle.isXCTestRunner else {
			return mainBundle
		}

		return Bundle.testBundle ?? mainBundle
	}()
	
	static func queryDirectoryURL(for bundleName: String) -> URL? {
		return effectiveBundle
			.resourceURL?
			.appendingPathComponent("\(bundleName).bundle", isDirectory: true)
			.appendingPathComponent("Contents/Resources/queries", isDirectory: true)
	}

	static func queryURL(named queryName: String, for bundleName: String) -> URL? {
		let fileName = "\(queryName).scm"

		return queryDirectoryURL(for: bundleName)?.appendingPathComponent(fileName, isDirectory: false)
	}

	static func query(for defintion: Query.Definition, bundleName: String, for language: Language) throws -> Query? {
		let queryURL = queryURL(named: defintion.name, for: bundleName)

		return try queryURL
			.flatMap { try? Data(contentsOf: $0) }
			.map { try Query(language: language, data: $0) }
	}
}
#endif
