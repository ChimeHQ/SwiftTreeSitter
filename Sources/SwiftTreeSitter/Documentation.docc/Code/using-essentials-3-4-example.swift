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

let tree = parser.parse(source)!

print("tree: ", tree)

let newSource = """
func hello() {
    print("hello from SwiftTreeSitter")
}
"""

let edit = InputEdit(startByte: 34,
                     oldEndByte: 45,
                     newEndByte: 49,
                     startPoint: Point(row: 1, column: 22),
                     oldEndPoint: Point(row: 1, column: 33),
                     newEndPoint: Point(row: 1, column: 37))

tree.edit(edit)
