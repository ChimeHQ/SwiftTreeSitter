<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Discord][discord badge]][discord]

</div>

# SwiftTreeSitter

Swift API for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system.

- Close to full coverage of the C API
- Swift/Foundation types where possible
- Standard query result mapping for highlights and injections
- Query predicate/directive support via `ResolvingQueryCursor` and `ResolvingQueryMatchSequence`

SwiftTreeSitter is fairly low-level. If you are looking a higher-level system for syntax highlighting and other syntactic operations, you might want to have a look at [Neon](https://github.com/ChimeHQ/Neon).

📖 [Documentation][documentation] is available in DocC format.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
],
targets: [
    .target(
        name: "MySwiftTreeSitterTarget",
        dependencies: ["SwiftTreeSitter"]
	),
    .target(
        name: "MySwiftTreeSitterLayerTarget",
        dependencies: [
            .product(name: "SwiftTreeSitterLayer", package: "SwiftTreeSitter"),
		]
	),
]
```

## SwiftTreeSitterLayer

The core SwiftTreeSitter library is largely a wrapper around the tree-sitter C runtime. But, there are many common uses that require substantial work to support. One of the more-popular ones is language "injections". This is when one language is nested inside of another - like CSS within an HTML document.

SwiftTreeSitterLayer supports arbitrary nested language resolution and querying, as well as snapshotting for easier compatibility with Swift concurrency. Neon may still be an easier way to integrate tree-sitter into your project, but SwiftTreeSitterLayer may be a good middle-ground.

SwiftTreeSitterLayer is still quite rough, and nested languages can have serious peformance implications.

## Highlighting

A very common use of tree-sitter is to do syntax highlighting. It is possible to use this library directly, especially if your source text does not change. Here's a little example that sets everything up with a SPM-bundled language.

First, check out how it works with SwiftTreeSitterLayer.

```swift
forthcoming...
```

You can also use SwiftTreeSitter directly.

Note: the query url discovery is broken in the current release, but is fixed on the main branch.

```swift
let language = Language(language: tree_sitter_swift(), name: "Swift")

let parser = Parser()
try parser.setLanguage(language)

let input = """
func main() {}
"""
let tree = parser.parse(input)!

let query = try language.query(contentsOf: language.highlightsFileURL!)

let cursor = query.execute(in: tree)
let resolvingCursor = ResolvingQueryCursor(cursor: cursor, context: .init(string: input))

for namedRange in resolvingCursor.highlights() {
    print("range: ", namedRange)
}
```

## Language Parsers

Tree-sitter language parsers are separate projects, and you'll probably need at least one. More details are available in the [documentation][documentation]. How they can be installed an incorporated varies. Since you're here, you might find SPM the most convenient.

| Parser | Make | SPM | Official Repo |
| --- | :---: | :---: | :---: |
| [Bash](https://github.com/tree-sitter/tree-sitter-bash) | | ✅ | ✅ |
| [C](https://github.com/tree-sitter/tree-sitter-c) | | ✅ | ✅ |
| [C++](https://github.com/tree-sitter/tree-sitter-cpp) | | ✅ | ✅ |
| [C#](https://github.com/tree-sitter/tree-sitter-c-sharp) | | ✅ | ✅ |
| [Clojure](https://github.com/mattmassicotte/tree-sitter-clojure/tree/feature/spm) | | ✅ | |
| [CMake](https://github.com/uyha/tree-sitter-cmake) | | | |
| [Comment](https://github.com/stsewd/tree-sitter-comment) | | | |
| [CSS](https://github.com/lukepistrol/tree-sitter-css/tree/feature/spm) | ✅ | ✅ | |
| [D](https://github.com/CyberShadow/tree-sitter-d) | | | |
| [Dart](https://github.com/UserNobody14/tree-sitter-dart) | | | |
| [Dockerfile](https://github.com/camdencheek/tree-sitter-dockerfile) | ✅ | ✅ | ✅ |
| [Diff](https://github.com/the-mikedavis/tree-sitter-diff) | | ✅ | ✅ |
| [Elixir](https://github.com/elixir-lang/tree-sitter-elixir) | ✅ | ✅ | ✅ |
| [Elm](https://github.com/elm-tooling/tree-sitter-elm) | | ✅ | ✅ |
| [Erlang](https://github.com/AbstractMachinesLab/tree-sitter-erlang) | | | |
| [Fish](https://github.com/ram02z/tree-sitter-fish) | | | |
| [Fortran](https://github.com/stadelmanma/tree-sitter-fortran) | | | |
| [gitattributes](https://github.com/ObserverOfTime/tree-sitter-gitattributes) | | | |
| [gitignore](https://github.com/shunsambongi/tree-sitter-gitignore) | | | |
| [Go](https://github.com/tree-sitter/tree-sitter-go) | ✅ | ✅ | ✅ |
| [GoMod](https://github.com/camdencheek/tree-sitter-go-mod) | ✅ | ✅ | ✅ |
| [GoWork](https://github.com/omertuc/tree-sitter-go-work) | ✅ | | |
| [graphql](https://github.com/bkegley/tree-sitter-graphql) | | | |
| [Hack](https://github.com/slackhq/tree-sitter-hack) | | | |
| [Haskell](https://github.com/tree-sitter/tree-sitter-haskell) | | ✅ | ✅ |
| [HCL](https://github.com/MichaHoffmann/tree-sitter-hcl) | | ✅ | ✅ |
| [HTML](https://github.com/tree-sitter/tree-sitter-html) | | ✅ | ✅ |
| [Java](https://github.com/tree-sitter/tree-sitter-java) | ✅ | ✅ | ✅ |
| [Javascript](https://github.com/tree-sitter/tree-sitter-javascript) | | ✅ | ✅ |
| [JSON](https://github.com/tree-sitter/tree-sitter-json) | ✅ | ✅ | ✅ |
| [Json5](https://github.com/Joakker/tree-sitter-json5) | | | |
| [JSDoc](https://github.com/tree-sitter/tree-sitter-jsdoc) | | ✅ | ✅ |
| [Julia](https://github.com/tree-sitter/tree-sitter-julia) | | ✅ | ✅ |
| [Kotlin](https://github.com/fwcd/tree-sitter-kotlin) | ✅ | | |
| [Latex](https://github.com/latex-lsp/tree-sitter-latex) | ✅ | ✅ | |
| [LLVM](https://github.com/benwilliamgraham/tree-sitter-llvm) | | | |
| [Lua](https://github.com/Azganoth/tree-sitter-lua) | | ✅ | ✅ |
| [Make](https://github.com/alemuller/tree-sitter-make) | | | |
| [Markdown](https://github.com/MDeiml/tree-sitter-markdown) | | ✅ | ✅ |
| [Markdown](https://github.com/mattmassicotte/tree-sitter-markdown) | ✅ | | |
| [OCaml](https://github.com/tree-sitter/tree-sitter-ocaml) | | ✅ | ✅ |
| [Pascal](https://github.com/Isopod/tree-sitter-pascal) | | | |
| [Perl](https://github.com/ganezdragon/tree-sitter-perl) | | ✅ | ✅ |
| [PHP](https://github.com/tree-sitter/tree-sitter-php) | ✅ | ✅ | ✅ |
| [PowerShell](https://github.com/PowerShell/tree-sitter-PowerShell) | | | |
| [Python](https://github.com/tree-sitter/tree-sitter-python) | | ✅ | ✅ |
| [R](https://github.com/r-lib/tree-sitter-r) | | | |
| [Racket](https://github.com/6cdh/tree-sitter-racket) | | | |
| [Regex](https://github.com/tree-sitter/tree-sitter-regex) | | | |
| [Ruby](https://github.com/tree-sitter/tree-sitter-ruby) | ✅ | ✅ | ✅ |
| [Rust](https://github.com/tree-sitter/tree-sitter-rust) | | ✅ | ✅ |
| [Scala](https://github.com/tree-sitter/tree-sitter-scala) | | ✅ | ✅ |
| [Scheme](https://github.com/6cdh/tree-sitter-scheme) | | | |
| [Scss](https://github.com/serenadeai/tree-sitter-scss) | | | |
| [SQL](https://github.com/DerekStride/tree-sitter-sql/tree/gh-pages) | | ✅ | ✅ |
| [Sqlite](https://github.com/dhcmrlchtdj/tree-sitter-sqlite) | | | |
| [SSH](https://github.com/metio/tree-sitter-ssh-client-config) | | ✅ | ✅ |
| [Swift](https://github.com/alex-pinkus/tree-sitter-swift/tree/with-generated-files) | ✅ | ✅ | ✅ |
| [TOML](https://github.com/mattmassicotte/tree-sitter-toml/feature/spm) | | ✅ | |
| [Tree-sitter query language](https://github.com/nvim-treesitter/tree-sitter-query) | | ✅ | ✅ |
| [Typescript](https://github.com/tree-sitter/tree-sitter-typescript) | | ✅ | ✅ |
| [Verilog](https://github.com/tree-sitter/tree-sitter-verilog) | | ✅ | ✅ |
| [Vue](https://github.com/ikatyang/tree-sitter-vue) | | | |
| [YAML](https://github.com/mattmassicotte/tree-sitter-yaml/tree/feature/spm) | | ✅ | |
| [Zig](https://github.com/maxxnino/tree-sitter-zig) | ✅ | ✅ | ✅ |

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. A [Discord server][discord] is also available for live help, but I have a strong bias towards answering in the form of documentation.

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/ChimeHQ/SwiftTreeSitter/actions
[build status badge]: https://github.com/ChimeHQ/SwiftTreeSitter/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FSwiftTreeSitter%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[discord]: https://discord.gg/esFpX6sErJ
[discord badge]: https://img.shields.io/badge/Discord-purple?logo=Discord&label=Chat&color=%235A64EC
