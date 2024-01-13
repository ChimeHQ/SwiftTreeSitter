import Foundation

#if !os(WASI)
extension Bundle {
	var isXCTestRunner: Bool {
#if DEBUG
		return NSClassFromString("XCTest") != nil
#else
		return false
#endif
	}

	static var testBundle: Bundle? {
		return allBundles.first(where: {
			$0.bundlePath.components(separatedBy: "/").last?.contains("Tests.xctest") == true
		})
	}
}
#endif

