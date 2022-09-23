import Foundation

public extension String {
	/// Produces a `TextProvider` for use with `ResolvingQueryCursor`.
	var cursorTextProvider: ResolvingQueryCursor.TextProvider {
		return { (nsRange, _) in
			guard let range = Range<String.Index>(nsRange, in: self) else {
				return nil
			}

			return String(self[range])
		}
	}
}
