import Foundation

/// A combined name and range
///
/// Useful for generalizing data from query matches.
public struct NamedRange {
	public let name: String
	public let range: NSRange

	public init(name: String, range: NSRange) {
		self.name = name
		self.range = range
	}
}

public extension QueryMatch {
	/// Intrepret the match using the "injections.scm" definition
	///
	/// - `injection.content` defines the range of the injection
	/// - a node with `injection.language` specifies the value of the language in the text
	/// - if that is not prsent, uses `injection.language` metadata
	///
	/// If `textProvider` is nil and a node contents is needed, the injection is dropped.
	func injection(with textProvider: ResolvingQueryCursor.TextProvider?) -> NamedRange? {
		guard let range = captures(named: "injection.content").first?.range else {
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

		return NamedRange(name: language, range: range)
	}
}
