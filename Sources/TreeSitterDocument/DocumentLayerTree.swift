import Foundation

import SwiftTreeSitter

public extension Query {
	enum Name: Hashable, Sendable {
		case highlights
		case injections
	}
}

public final class DocumentLayerTree {
	public struct ContentMutation: Hashable {
		public let range: NSRange
		public let delta: Int
		public let limit: Int
	}

	public enum Failure: Error {
		case couldBeHighLatency
	}

	public typealias TextProvider = ResolvingQueryCursor.TextProvider
	public typealias LanguageProvider = (String) throws -> Language
	public typealias InvalidationHandler = (IndexSet, [ContentMutation]) -> Void

	public struct Configuration {
		public let language: Language
		public let locationTransformer: Point.LocationTransformer?
		public let invalidationHandler: InvalidationHandler?
		public let injectedLanguageProvider: LanguageProvider?

		public init(language: Language,
					locationTransformer: Point.LocationTransformer? = nil,
					invalidationHandler: InvalidationHandler? = nil,
					injectedLanguageProvider: LanguageProvider? = nil) {
			self.language = language
			self.locationTransformer = locationTransformer
			self.invalidationHandler = invalidationHandler
			self.injectedLanguageProvider = injectedLanguageProvider
		}
	}

	private var oldEndPoint: Point?
	private var pendingMutations = [ContentMutation]()
	private let rootLayer: LanguageLayer
	private let configuration: Configuration
	private let semaphore = DispatchSemaphore(value: 1)

	public init(configuration: Configuration) throws {
		self.configuration = configuration
		self.rootLayer = try LanguageLayer(language: configuration.language)
	}
}

extension DocumentLayerTree {
	public func replaceContent(with string: String) {
		self.oldEndPoint = nil
		let fullRange = rootLayer.spanningRange ?? NSRange(0..<0)
		let delta = string.utf16.count - fullRange.length

		didChangeContent(to: string, in: fullRange, delta: delta)
	}

	public func willChangeContent(in range: NSRange) {
		oldEndPoint = configuration.locationTransformer?(range.upperBound)
	}

	public func didChangeContent(to string: String, in range: NSRange, delta: Int, limit: Int? = nil) {
		let readFunction = Parser.readFunction(for: string, limit: limit)

		didChangeContent(in: range, delta: delta, readHandler: readFunction)
	}

	public func didChangeContent(in range: NSRange,
								 delta: Int,
								 readHandler: Parser.ReadBlock) {
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

		let set = rootLayer.parse(with: readHandler)
	}
}

extension DocumentLayerTree {
	private func languageLayer(for range: NSRange) throws -> LanguageLayer {
		return rootLayer
	}

	private func documentFragments(for range: NSRange) throws -> [(LanguageLayer, NSRange)] {
		return [(rootLayer, range)]
	}
}

extension DocumentLayerTree {
	public func executeQuery(_ query: Query, in range: NSRange) throws -> ResolvingQueryCursor {
		
		let layer = try self.languageLayer(for: range)

		return try layer.executeQuery(query, in: range)
	}
}
