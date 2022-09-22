import SwiftTreeSitter
import TreeSitterSwift

let language = Language(language: tree_sitter_swift())

let parser = Parser()
try parser.setLanguage(language)

let source = """
func hello() {
	print("hello from tree-sitter")
}
"""

let tree = parser.parse(source)

print("tree: ", tree)

let url = Bundle.main
              .resourceURL
              .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
              .appendingPathComponent("queries/highlights.scm")

let query = try language.query(contentsOf: url!)

let cursor = query.execute(node: tree.rootNode!)
