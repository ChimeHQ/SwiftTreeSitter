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
