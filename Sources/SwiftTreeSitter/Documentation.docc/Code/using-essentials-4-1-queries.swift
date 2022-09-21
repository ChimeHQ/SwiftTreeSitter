import SwiftTreeSitter
import TreeSitterSwift

let language = Language(language: tree_sitter_swift())

// find the SPM-packaged queries
let url = Bundle.main
              .resourceURL
              .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
              .appendingPathComponent("queries/highlights.scm")

// this can be very expensive, depending on the language grammar/queries
let query = try language.query(contentsOf: url!)

let tree = parseText() // <- omitting for clarity

let queryCursor = query.execute(node: tree.rootNode!, in: tree)

// the performance of nextMatch is highly dependent on the nature of the queries,
// language grammar, and size of input
while let match = queryCursor.nextMatch() {
    print("match: ", match)
}
