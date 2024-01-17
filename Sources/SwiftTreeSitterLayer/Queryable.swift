import Foundation

import SwiftTreeSitter

public protocol Queryable {
	associatedtype Cursor : Sequence<QueryMatch>
	associatedtype Region

	func executeQuery(_ queryDef: Query.Definition, in region: Region) throws -> Cursor
}

extension Queryable {
	public func highlights(in region: Region, provider: SwiftTreeSitter.Predicate.TextProvider) throws -> [NamedRange] {
		try withoutActuallyEscaping(provider) { escapingClosure in
			try executeQuery(.highlights, in: region)
				.resolve(with: .init(textProvider: escapingClosure))
				.highlights()
		}
	}
}

extension Queryable where Region == IndexSet {
	public func executeQuery(_ queryDef: Query.Definition, in range: NSRange) throws -> Cursor {
		try executeQuery(queryDef, in: IndexSet(integersIn: range))
	}

	public func highlights(in range: NSRange, provider: SwiftTreeSitter.Predicate.TextProvider) throws -> [NamedRange] {
		try highlights(in: IndexSet(integersIn: range), provider: provider)
	}
}
