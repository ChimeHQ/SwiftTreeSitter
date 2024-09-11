import Foundation

import TreeSitter

/// A structure that holds a language name and its assoicated queries.
public struct LanguageData: Sendable {
	public let name: String
	public let queries: [Query.Definition: Query]

	public init(name: String, queries: [Query.Definition: Query]) {
		self.name = name
		self.queries = queries
	}
}

enum LanguageConfigurationError: Error {
	case queryDirectoryNotFound
	case queryDirectoryNotReadable(URL)
}

/// A structure that holds a language parser, name, and its assoicated queries.
public struct LanguageConfiguration: Sendable {
	public let language: Language
	public let data: LanguageData

	public init(_ language: Language, data: LanguageData) {
		self.language = language
		self.data = data
	}

	public init(_ language: Language, name: String, queries: [Query.Definition: Query]) {
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
	public init(_ tsLanguage: OpaquePointer, name: String, queries: [Query.Definition: Query]) {
        self.init(Language(tsLanguage), name: name, queries: queries)
    }

    /// Create a configuration with a name assumed to match a bundle.
    ///
    /// The bundle must be nested within resources and follow the pattern `TreeSitter\(name)_TreeSitter\(name)`.
	public init(_ language: Language, name: String) throws {
		let bundleName = "TreeSitter\(name)_TreeSitter\(name)"

		try self.init(language, name: name, bundleName: bundleName)
	}

    /// Create a configuration with a name assumed to match a bundle.
    ///
    /// The bundle must be nested within resources and follow the pattern `TreeSitter\(name)_TreeSitter\(name)`.
	public init(_ tsLanguage: OpaquePointer, name: String) throws {
		try self.init(Language(tsLanguage), name: name)
	}

	public init(_ language: Language, name: String, bundleName: String) throws {
		guard let queriesURL = Self.bundleQueriesDirectoryURL(for: bundleName) else {
			throw LanguageConfigurationError.queryDirectoryNotFound
		}

		let path = queriesURL.standardizedFileURL.path

		if FileManager.default.isReadableFile(atPath: path) == false {
			throw LanguageConfigurationError.queryDirectoryNotReadable(queriesURL)
		}

		let queries = try Query.queries(for: language, in: queriesURL)

		self.init(language, name: name, queries: queries)
	}

	public init(_ tsLanguage: OpaquePointer, name: String, bundleName: String) throws {
		try self.init(Language(tsLanguage), name: name, bundleName: bundleName)
	}

	public init(_ language: Language, name: String, queriesURL: URL) throws {
		let queries = try Query.queries(for: language, in: queriesURL)

		self.init(language, name: name, queries: queries)
	}

	public init(_ tsLanguage: OpaquePointer, name: String, queriesURL: URL) throws {
		try self.init(Language(tsLanguage), name: name, queriesURL: queriesURL)
	}
}

extension LanguageConfiguration {
	static let bundleContainerURL: URL? = {
		let mainBundle = Bundle.main

		guard mainBundle.isXCTestRunner else {
			return mainBundle.resourceURL
		}

		// we have to go up one directory, because Xcode puts SPM dependency bundles
		return Bundle.testBundle?.bundleURL.deletingLastPathComponent()
	}()

	static func bundleQueriesDirectoryURL(for bundleName: String) -> URL? {
        let bundlePath = bundleContainerURL?.appendingPathComponent("\(bundleName).bundle", isDirectory: true)
#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        return bundlePath?.appendingPathComponent("queries", isDirectory: true)
#else
        return bundlePath?.appendingPathComponent("Contents/Resources/queries", isDirectory: true)
#endif
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
