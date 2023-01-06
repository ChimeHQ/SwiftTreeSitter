import Foundation

/// A combined name and range
///
/// Useful for generalizing data from query matches.
public struct NamedRange: Codable, Equatable, Sendable, Hashable {
	public let nameComponents: [String]
	public let tsRange: TSRange

	public init(nameComponents: [String], tsRange: TSRange) {
		self.nameComponents = nameComponents
		self.tsRange = tsRange
	}

	public var name: String {
		return nameComponents.joined(separator: ".")
	}

	public var range: NSRange {
		return tsRange.bytes.range
	}
}

public extension QueryMatch {
	/// Interpret the match using the "injections.scm" definition
	///
	/// - `injection.content` defines the range of the injection
	/// - a node with `injection.language` specifies the value of the language in the text
	/// - if that is not present, uses `injection.language` metadata
	///
	/// If `textProvider` is nil and a node contents is needed, the injection is dropped.
	func injection(with textProvider: ResolvingQueryCursor.TextProvider?) -> NamedRange? {
		guard let contentCapture = captures(named: "injection.content").first else {
			return nil
		}

		let languageCapture = captures(named: "injection.language").first

		let nodeLanguage: String?

		if let node = languageCapture?.node {
			nodeLanguage = textProvider?(node.range, node.pointRange)
		} else {
			nodeLanguage = nil
		}

		let setLanguage = metadata["injection.language"]

		guard let language = nodeLanguage ?? setLanguage else {
			return nil
		}

		return NamedRange(nameComponents: [language], tsRange: contentCapture.node.tsRange)
	}
}

public extension QueryCapture {
	/// Interpret the capture using the "highlights.scm" definition
	///
	/// Capture names are used without modification.
	var highlight: NamedRange? {
		let components = nameComponents
		guard components.isEmpty == false else { return nil }

		return NamedRange(nameComponents: components, tsRange: node.tsRange)
	}
}

public extension QueryCursor {
	/// Interpret the cursor using the "injections.scm" definition
	///
	/// If `textProvider` is nil and a node contents is needed, the injection is dropped.
	func injections(with textProvider: ResolvingQueryCursor.TextProvider?) -> [NamedRange] {
		return compactMap({ $0.injection(with: textProvider) })
	}

	/// Interpret the cursor using the "highlights.scm" definition
	///
	/// Results are sorted such that less-specific matches come before more-specific. This helps to resolve ambiguous patterns.
	func highlights() -> [NamedRange] {
		return map({ $0.captures })
			.flatMap({ $0 })
			.sorted()
			.compactMap { $0.highlight }
	}
}

public extension ResolvingQueryCursor {
	/// Interpret the cursor using the "injections.scm" definition
	///
	/// If the cursor's textProvider is nil and a node contents is needed, the injection is dropped.
	func injections() -> [NamedRange] {
		return compactMap({ $0.injection(with: textProvider) })
	}

	/// Interpret the cursor using the "highlights.scm" definition
	///
	/// Results are sorted such that less-specific matches come before more-specific. This helps to resolve ambiguous patterns.
	func highlights() -> [NamedRange] {
		return map({ $0.captures })
			.flatMap({ $0 })
			.sorted()
			.compactMap { $0.highlight }
	}
}
