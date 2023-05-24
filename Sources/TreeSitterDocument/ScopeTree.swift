import Foundation
import SwiftTreeSitter

struct ScopeTree {
	let rootScope: Scope

	func defines(_ identifier: String, within range: NSRange) -> Bool {
		return false
	}
}

struct Scope {
	let children: [Scope]
	let definedIdentifiers: Set<String>
	let range: NSRange
	let pointRange: Range<Point>

	func defines(_ identifier: String) -> Bool {
		return definedIdentifiers.contains(identifier)
	}
}
