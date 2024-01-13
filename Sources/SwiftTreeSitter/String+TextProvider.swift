import Foundation

extension String {
	/// Produces a `TextProvider` for use with `Predicate` resolution.
	@available(*, deprecated, renamed: "predicateTextProvider")
	public var cursorTextProvider: Predicate.TextProvider {
		return { (nsRange, _) in
			guard let range = Range<String.Index>(nsRange, in: self) else {
				return nil
			}

			return String(self[range])
		}
	}

	public var predicateTextProvider: Predicate.TextProvider {
		return { (nsRange, _) in
			guard let range = Range<String.Index>(nsRange, in: self) else {
				return nil
			}

			return String(self[range])
		}
	}
}
