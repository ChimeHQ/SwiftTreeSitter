import Foundation

extension IndexSet {
	init(integersIn nsRange: NSRange) {
		self.init(integersIn: Range(nsRange) ?? 0..<0)
	}
}
