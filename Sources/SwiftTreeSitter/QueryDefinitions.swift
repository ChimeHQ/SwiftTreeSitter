import Foundation

extension Query {
	public enum Definition: Hashable, Sendable {
		case injections
		case highlights
		case locals
		case custom(String)

		public var name: String {
			switch self {
			case .injections:
				return "injections"
			case .highlights:
				return "highlights"
			case .locals:
				return "locals"
			case .custom(let value):
				return value
			}
		}

		public var filename: String {
			"\(name).scm"
		}
	}
}

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

	public init(name: String, tsRange: TSRange) {
		let components = name.split(separator: ".").map(String.init)

		self.init(nameComponents: components, tsRange: tsRange)
	}

	public init (name: String, range: NSRange, pointRange: Range<Point> = Point.zero..<Point.zero) {
		let tsRange = TSRange(points: pointRange,
							  bytes: range.byteRange)

		self.init(name: name, tsRange: tsRange)
	}

	public var name: String {
		return nameComponents.joined(separator: ".")
	}

	public var range: NSRange {
		return tsRange.bytes.range
	}
}

extension NamedRange: Comparable {
	public static func < (lhs: NamedRange, rhs: NamedRange) -> Bool {
		if lhs.tsRange != rhs.tsRange {
			return lhs.tsRange < rhs.tsRange
		}

		return lhs.nameComponents.count < rhs.nameComponents.count
	}
}

extension NamedRange: CustomDebugStringConvertible {
	public var debugDescription: String {
		"<\"\(name)\": \(tsRange)>"
	}
}

extension QueryMatch {
	/// Interpret the match using the "injections.scm" definition
	///
	/// - `injection.content` defines the range of the injection
	/// - a node with `injection.language` specifies the value of the language in the text
	/// - if that is not present, uses `injection.language` metadata
	///
	/// If `textProvider` is nil and a node contents is needed, the injection is dropped.
	public func injection(with textProvider: Predicate.TextProvider) -> NamedRange? {
		guard let contentCapture = captures(named: "injection.content").first else {
			return nil
		}

		let languageCapture = captures(named: "injection.language").first

		let nodeLanguage: String?

		if let node = languageCapture?.node {
			nodeLanguage = textProvider(node.range, node.pointRange)
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

extension QueryCapture {
	/// Interpret the capture using the "highlights.scm" definition
	///
	/// Capture names are used without modification.
	public var highlight: NamedRange? {
		let components = nameComponents
		guard components.isEmpty == false else { return nil }

		return NamedRange(nameComponents: components, tsRange: node.tsRange)
	}
}

extension QueryCapture {
	public var locals: NamedRange? {
		return highlight
	}
}

extension Sequence where Element == QueryMatch {
	private var captures: [QueryCapture] {
		map({ $0.captures })
			.flatMap({ $0 })
	}

	/// Interpret matches using the "highlights.scm" definition
	///
	/// Results are sorted such that less-specific matches come before more-specific. This helps to resolve ambiguous patterns.
	public func highlights() -> [NamedRange] {
		captures
			.sorted()
			.compactMap { $0.highlight }
	}

	/// Interpret the match using the "injections.scm" definition.
	///
	/// - `injection.content` defines the range of the injection
	/// - a node with `injection.language` specifies the value of the language in the text
	/// - if that is not present, uses `injection.language` metadata
	///
	/// If `textProvider` returns nil and node contents is needed, the injection is dropped.
	public func injections(with textProvider: Predicate.TextProvider) -> [NamedRange] {
		return compactMap({ $0.injection(with: textProvider) })
	}

	/// Interpret the cursor using the "locals.scm" definition
	public func locals() -> [NamedRange] {
		captures
			.compactMap({ $0.locals })
	}
}

@available(*, deprecated, message: "Please use ResolvingQueryMatchSequence")
extension ResolvingQueryCursor {
	public func injections() -> [NamedRange] {
		return compactMap({ $0.injection(with: context.textProvider) })
	}
}
