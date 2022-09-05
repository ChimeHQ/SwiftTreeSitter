[![Build Status][build status badge]][build status]
[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]

# SwiftTreeSitter

Swift wrappers for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system.

SwiftTreeSitter is fairly low-level. If you are looking a higher-level system for syntax highlighting and other syntactic operations, you might want to have a look at [Neon](https://github.com/ChimeHQ/Neon).

## Integration

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
]
```

## Usage

Basic parsing:

```swift
// import the tree-sitter bindings
import SwiftTreeSitter

// import the tree-sitter swift parser (confusing naming, I know)
import TreeSitterSwift

// create a language
let language = Language(language: tree_sitter_swift())

// create a parser
let parser = Parser()
try parser.setLanguage(language)

let source = """
func hello() {
    print("hello from tree-sitter")
}
"""

let tree = parser.parse(source)

print("tree: ", tree)
```

Tree-sitter operates on byte indices and line/character-offset pairs (called a Point). It is, unfortunately, your responsibility to map your text storage and edits into these types. For the most part, 


Processing edits:

```swift
// tree-sitter operates on byte indices and line/character-offset pairs (called a Point). It is, unfortunately,
// your responsibility to map your text storage and edits into these types

let edit = InputEdit(startByte: editStartByteOffset,
                                oldEndByte: preEditEndByteOffset,
                                newEndByte: postEditEndByteOffset,
                                startPoint: editStartPoint,
                                oldEndPoint: preEditEndPoint,
                                newEndPoint: postEditEndPoint)

// apply the edit first
existingTree.edit(edit)

// then, re-parse the text to build a new tree
let newTree = parser.parse(existingTree, string: fullText)

// you can now compute a diff to determine what has changed
let changedRanges = existingTree.changedRanges(newTree)
```

Using queries:

```swift
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
```

## Language Parsers

Tree-sitter language parsers are separate projects, and you'll probably need at least one. They can also be built with SPM, though they are more complex. If you would like SPM support for parser that doesn't have it yet, let me know and I'll help!

**Parsers available via SPM:** (\* not merged into official repo yet)

- [Bash](https://github.com/lukepistrol/tree-sitter-bash/tree/feature/spm)\*
- [C](https://github.com/tree-sitter/tree-sitter-c)
- [C++](https://github.com/tree-sitter/tree-sitter-cpp)
- [C#](https://github.com/tree-sitter/tree-sitter-c-sharp)
- [CSS](https://github.com/lukepistrol/tree-sitter-css/tree/feature/spm)\*
- [Go](https://github.com/tree-sitter/tree-sitter-go)
- [GoMod](https://github.com/camdencheek/tree-sitter-go-mod)
- [HTML](https://github.com/mattmassicotte/tree-sitter-html/tree/feature/spm)\*
- [Java](https://github.com/tree-sitter/tree-sitter-java)
- [Javascript](https://github.com/tree-sitter/tree-sitter-javascript)
- [JSON](https://github.com/tree-sitter/tree-sitter-json)
- [Lua](https://github.com/Azganoth/tree-sitter-lua)
- [Markdown](https://github.com/mattmassicotte/tree-sitter-markdown-2/tree/feature/spm)\*
- [PHP](https://github.com/tree-sitter/tree-sitter-php)
- [Python](https://github.com/lukepistrol/tree-sitter-python/tree/feature/spm)\*
- [Ruby](https://github.com/tree-sitter/tree-sitter-ruby)
- [Rust](https://github.com/tree-sitter/tree-sitter-rust)
- [Swift](https://github.com/alex-pinkus/tree-sitter-swift/tree/with-generated-files)
- [YAML](https://github.com/mattmassicotte/tree-sitter-yaml/tree/feature/spm)\*

While SPM is nice, it isn't a requirement. You can use git submodules. You can even build them yourself. In fact, I've struggled with this so much that I began adapting the runtime's Makefile for the parsers themselves. This is a [work-in-progress](https://github.com/tree-sitter/tree-sitter/issues/1488). But, if the parser you'd like to use doesn't have a Makefile, let me know and I'll help get it set up.

## Predicate/Directive Support

`QueryMatch` provides an API for getting at query predicates and directives. You are free to use/evaluate them yourself. However, there is also a `ResolvingQueryCursor`, which wraps a standard `QueryCursor`, but allows for resolution of predicates. It also provides some facilities for preloading all `QueryMatch` objects from the underlying `QueryCursor`, which can help with performance in some situations.

The following predicates are parsed and transformed into structured `Predicate` cases. All others are turned into the `generic` case.

- `eq?`: fully supported
- `not-eq?`: fully supported
- `match?`: fully supported
- `not-match?`: fully supported
- `any-of?`: fully supported
- `not-any-of?`: fully supported
- `is-not?`: parsed, but not implemented
- `set!`: parsed, but not implemented

Please open up an issue if you need additional support here.

```swift
let resolvingCursor = ResolvingQueryCursor(cursor: queryCursor)

// this function takes an NSRange and Range<Point>, and returns
// the contents in your source text
let provider: TextProvider = { range, pointRange in ... }

resolvingCursor.prepare(with: provider)

// ResolvingQueryCursor conforms to Sequence
for match in resolvingCursor {
    print("match: ", match)
}
```

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[build status]: https://github.com/ChimeHQ/SwiftTreeSitter/actions
[build status badge]: https://github.com/ChimeHQ/SwiftTreeSitter/workflows/CI/badge.svg
[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/SwiftTreeSitter
[platforms]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FSwiftTreeSitter%2Fbadge%3Ftype%3Dplatforms
