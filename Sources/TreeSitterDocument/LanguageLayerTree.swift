import Foundation

import SwiftTreeSitter

/// Represents a source document as a tree of language sections.
public final class LanguageLayerTree {
	public typealias TextProvider = ResolvingQueryCursor.TextProvider
	public typealias LanguageProvider = (String) -> LanguageConfiguration?
	public typealias InvalidationHandler = (IndexSet) -> Void
	public typealias QueryProvider = (LanguageConfiguration, Query.Definition) throws -> Query?

	public struct Configuration {
		public let locationTransformer: Point.LocationTransformer?
		public let invalidationHandler: InvalidationHandler?
		public let languageProvider: LanguageProvider?

		public init(locationTransformer: Point.LocationTransformer? = nil,
					invalidationHandler: InvalidationHandler? = nil,
					languageProvider: LanguageProvider? = nil) {
			self.locationTransformer = locationTransformer
			self.invalidationHandler = invalidationHandler
			self.languageProvider = languageProvider
		}
	}

	private var oldEndPoint: Point?
	private let rootLayer: LanguageLayer
	private let configuration: Configuration

	public init(rootLanguageConfig: LanguageConfiguration, configuration: Configuration) throws {
		self.configuration = configuration
		self.rootLayer = try LanguageLayer(languageConfig: rootLanguageConfig, configuration: configuration)
	}
}

extension LanguageLayerTree {
	/// Completely rebuilds the tree from the source text.
	public func replaceContent(with string: String) {
		self.oldEndPoint = nil
		let fullRange = rootLayer.spanningRange ?? NSRange(0..<0)
		let delta = string.utf16.count - fullRange.length

		didChangeContent(to: string, in: fullRange, delta: delta)
	}

	/// Prepare for a content change.
	///
	/// This method must be called before any content changes have been applied that would affect how the configuration's `locationTransformer` parameter will behave.
	///
	/// - Parameter range: the range of content that will be affected by an edit
	public func willChangeContent(in range: NSRange) {
		oldEndPoint = configuration.locationTransformer?(range.upperBound)
	}

	/// Process a string representing text content.
	///
	/// This method is similar to `didChangeContent(in:delta:readHandler:)`, but it makes use of the immutability of String to meet the content requirements. This makes it much easier to use. However, this approach may not be able to achieve the same level of performance.
	///
	/// - Parameter string: the text content with the change applied
	/// - Parameter range: the range that was affected by the edit
	/// - Parameter delta: the change in length of the content
	/// - Parameter limit: the current length of the content
	public func didChangeContent(to string: String, in range: NSRange, delta: Int, limit: Int? = nil) {
		let readFunction = Parser.readFunction(for: string, limit: limit)
		let provider = string.cursorTextProvider

		didChangeContent(in: range, delta: delta, readHandler: readFunction, textProvider: provider)
	}

	/// Process a change in the underlying text content.
	///
	/// This method will re-parse the sections of the content needed by tree-sitter. It may do so **asynchronously** which means you **must** guarantee that `readHandler` provides a stable, thread-safe view of the content.
	///
	/// - Parameter range: the range that was affected by the edit
	/// - Parameter delta: the change in length of the content
	/// - Parameter readHandler: a function that returns the text data
	/// - Parameter textProvider: a function that returns text data by range
	public func didChangeContent(in range: NSRange,
								 delta: Int,
								 readHandler: Parser.ReadBlock,
								 textProvider: TextProvider?) {
		let oldEndPoint = self.oldEndPoint ?? .zero
		self.oldEndPoint = nil

		let inputEdit = InputEdit(range: range,
								  delta: delta,
								  oldEndPoint: oldEndPoint,
								  transformer: configuration.locationTransformer)

		guard let inputEdit else {
			assertionFailure("unable to build InputEdit")
			return
		}

		rootLayer.applyEdit(inputEdit)

		let set = rootLayer.parse(with: readHandler, provider: textProvider)

		configuration.invalidationHandler?(set)
	}
}

extension LanguageLayerTree {
	/// Execute a query against the full tree.
	public func executeQuery(_ query: Query.Definition, in set: IndexSet) throws -> LayeredQueryCursor {
		return try rootLayer.executeQuery(query, in: set)
	}

	/// Execute a query against the full tree.
	public func executeQuery(_ query: Query.Definition, in range: NSRange) throws -> LayeredQueryCursor {
		let set = IndexSet(integersIn: Range(range) ?? 0..<0)

		return try executeQuery(query, in: set)
	}
}
