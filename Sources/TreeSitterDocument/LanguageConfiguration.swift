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

extension LanguageConfiguration {
	public init(language: Language, name: String) throws {
		let bundleName = "TreeSitter\(name)_TreeSitter\(name)"

		try self.init(language: language, name: name, bundleName: bundleName)
	}

	public init(tsLanguage: UnsafePointer<TSLanguage>, name: String) throws {
		try self.init(language: Language(language: tsLanguage), name: name)
	}

	public init(language: Language, name: String, bundleName: String) throws {
		var queries: [Query.Definition: Query] = [:]

		if let query = try Self.query(named: "injections", bundleName: bundleName, for: language) {
			queries[.injections] = query
		}

		if let query = try Self.query(named: "highlights", bundleName: bundleName, for: language) {
			queries[.highlights] = query
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

		let testBundle = Bundle.allBundles .first(where: {
			$0.bundlePath.components(separatedBy: "/").last?.contains("Tests.xctest") == true
		})

		return testBundle ?? mainBundle
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

	static func query(named queryName: String, bundleName: String, for language: Language) throws -> Query? {
		let queryURL = queryURL(named: queryName, for: bundleName)

		return try queryURL
			.flatMap { try? Data(contentsOf: $0) }
			.map { try Query(language: language, data: $0) }
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
