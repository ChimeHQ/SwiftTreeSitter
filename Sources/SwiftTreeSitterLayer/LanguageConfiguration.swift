import Foundation
import SwiftTreeSitter
import tree_sitter

public struct LanguageData: Sendable {
	public let name: String
	public let queries: [Query.Definition: Query]

	public init(name: String, queries: [Query.Definition: Query]) {
		self.name = name
		self.queries = queries
	}
}

public struct LanguageConfiguration: Sendable {
	public let language: Language
	public let data: LanguageData

	public init(language: Language, data: LanguageData) {
		self.language = language
		self.data = data
	}

	public init(language: Language, name: String, queries: [Query.Definition: Query]) {
		self.language = language
		self.data = LanguageData(name: name, queries: queries)
	}

	public var name: String {
		data.name
	}

	public var queries: [Query.Definition: Query] {
		data.queries
	}
}

#if !os(WASI)
extension LanguageConfiguration {
	public init(language: Language, name: String) throws {
		let bundleName = "TreeSitter\(name)_TreeSitter\(name)"

		try self.init(language: language, name: name, bundleName: bundleName)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String) throws {
		try self.init(language: Language(tsLanguage), name: name)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String, queries: [Query.Definition: Query]) {
		self.init(language: Language(tsLanguage), name: name, queries: queries)
	}

	public init(language: Language, name: String, bundleName: String) throws {
		let queriesURL = Self.bundleQueriesDirectoryURL(for: bundleName)
		let queries = try queriesURL.flatMap { try Query.queries(for: language, in: $0) } ?? [:]

		self.init(language: language, name: name, queries: queries)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String, bundleName: String) throws {
		try self.init(language: Language(tsLanguage), name: name, bundleName: bundleName)
	}

	public init(language: Language, name: String, queriesURL: URL) throws {
		let queries = try Query.queries(for: language, in: queriesURL)

		self.init(language: language, name: name, queries: queries)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String, queriesURL: URL) throws {
		try self.init(language: Language(tsLanguage), name: name, queriesURL: queriesURL)
	}
}

extension LanguageConfiguration {
	static let effectiveBundle: Bundle = {
		let mainBundle = Bundle.main

		guard mainBundle.isXCTestRunner else {
			return mainBundle
		}

		return Bundle.testBundle ?? mainBundle
	}()

	static func bundleQueriesDirectoryURL(for bundleName: String) -> URL? {
		effectiveBundle
			.resourceURL?
			.appendingPathComponent("\(bundleName).bundle", isDirectory: true)
			.appendingPathComponent("Contents/Resources/queries", isDirectory: true)
	}
}

extension Query {
	static func query(definition: Query.Definition, for language: Language, in url: URL) throws -> Query? {
		let fullURL = url.appendingPathComponent(definition.filename).standardizedFileURL

		guard FileManager.default.isReadableFile(atPath: fullURL.path) else {
			return nil
		}

		return try Query(language: language, url: fullURL)
	}

	static func queries(for language: Language, in url: URL) throws -> [Query.Definition: Query] {
		var queries = [Query.Definition: Query]()

		if let query = try Self.query(definition: .injections, for: language, in: url) {
			queries[.injections] = query
		}

		if let query = try Self.query(definition: .highlights, for: language, in: url) {
			queries[.highlights] = query
		}

		if let query = try Self.query(definition: .locals, for: language, in: url) {
			queries[.locals] = query
		}

		return queries
	}
}
#endif
