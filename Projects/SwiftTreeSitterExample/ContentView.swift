import SwiftUI

import SwiftTreeSitter
import TreeSitterSwift

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
		.onAppear {
			do {
				try runTreeSitterTest()
			} catch {
				print("error: ", error)
			}
		}
    }

	func runTreeSitterTest() throws {
		let language = Language(language: tree_sitter_swift())

		let parser = Parser()
		try parser.setLanguage(language)

		let source = """
func example() {
    SomeType.method()
	variable.method()
}
"""

		let tree = parser.parse(source)!

		let url = Bundle.main
					  .resourceURL?
					  .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
					  .appendingPathComponent("Contents/Resources/queries/highlights.scm")

		let query = try language.query(contentsOf: url!)

		let cursor = query.execute(node: tree.rootNode!)

		let resolvingCursor = ResolvingQueryCursor(cursor: cursor)

		resolvingCursor.prepare(with: source.cursorTextProvider)

		let typeCaptures = resolvingCursor
			.map { $0.captures(named: "type") }
			.flatMap({ $0 })

		for capture in typeCaptures {
			print("matched range:", capture.range)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
