import SwiftTreeSitter
import TreeSitterSwift

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

let resolvingSequence = cursor.resolve(with: Predicate.Context(string: source))

let typeCaptures = cursor
	.map { $0.captures(named: "type") }
	.flatMap({ $0 })

for capture in typeCaptures {
	print("matched range:", capture.range)
}
