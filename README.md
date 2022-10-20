[![Build Status][build status badge]][build status]
[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

# SwiftTreeSitter

Swift API for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system.

- Close to full coverage of the C API
- Swift/Foundation types where possible
- Standard query result mapping for injections
- Query predicate support via `ResolvingQueryCursor`

SwiftTreeSitter is fairly low-level. If you are looking a higher-level system for syntax highlighting and other syntactic operations, you might want to have a look at [Neon](https://github.com/ChimeHQ/Neon).

📖 [Documentation][documentation] is available in DocC format.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
]
```

## Language Parsers

Tree-sitter language parsers are separate projects, and you'll probably need at least one. More details are available in the [documentation][documentation]. How they can be installed an incorporated varies. Since you're here, you might find SPM the most convenient.

| Parser | Make | SPM | Official Repo |
| --- | :---: | :---: | :---: |
| [Bash](https://github.com/lukepistrol/tree-sitter-bash/tree/feature/spm) | | ✅ | |
| [C](https://github.com/tree-sitter/tree-sitter-c) | | ✅ | ✅ |
| [C++](https://github.com/tree-sitter/tree-sitter-cpp) | | ✅ | ✅ |
| [C#](https://github.com/tree-sitter/tree-sitter-c-sharp) | | ✅ | ✅ |
| [Clojure](https://github.com/sogaiu/tree-sitter-clojure) | | | |
| [CMake](https://github.com/uyha/tree-sitter-cmake) | | | |
| [Comment](https://github.com/stsewd/tree-sitter-comment) | | | |
| [CSS](https://github.com/lukepistrol/tree-sitter-css/tree/feature/spm) | ✅ | ✅ | |
| [D](https://github.com/CyberShadow/tree-sitter-d) | | | |
| [Dart](https://github.com/UserNobody14/tree-sitter-dart) | | | |
| [Dockerfile](https://github.com/camdencheek/tree-sitter-dockerfile) | | | |
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
| [HTML](https://github.com/mattmassicotte/tree-sitter-html/tree/feature/spm) | | ✅ | |
| [Java](https://github.com/tree-sitter/tree-sitter-java) | ✅ | ✅ | ✅ |
| [Javascript](https://github.com/tree-sitter/tree-sitter-javascript) | | ✅ | ✅ |
| [JSON](https://github.com/tree-sitter/tree-sitter-json) | ✅ | ✅ | ✅ |
| [Json5](https://github.com/Joakker/tree-sitter-json5) | | | |
| [Julia](https://github.com/mattmassicotte/tree-sitter-julia/tree/feature/spm) | | ✅ | |
| [Kotlin](https://github.com/fwcd/tree-sitter-kotlin) | | | |
| [Latex](https://github.com/latex-lsp/tree-sitter-latex) | ✅ | | |
| [LLVM](https://github.com/benwilliamgraham/tree-sitter-llvm) | | | |
| [Lua](https://github.com/Azganoth/tree-sitter-lua) | | ✅ | ✅ |
| [Make](https://github.com/alemuller/tree-sitter-make) | | | |
| [Markdown](https://github.com/MDeiml/tree-sitter-markdown) | | ✅ | ✅ |
| [Markdown](https://github.com/mattmassicotte/tree-sitter-markdown) | ✅ | | |
| [OCaml](https://github.com/tree-sitter/tree-sitter-ocaml) | | | |
| [Pascal](https://github.com/Isopod/tree-sitter-pascal) | | | |
| [Perl](https://github.com/mattmassicotte/tree-sitter-perl/tree/feature/spm) | | ✅ | |
| [PHP](https://github.com/tree-sitter/tree-sitter-php) | ✅ | ✅ | ✅ |
| [PowerShell](https://github.com/PowerShell/tree-sitter-PowerShell) | | | |
| [Python](https://github.com/mattmassicotte/tree-sitter-python/feature/spm) | | ✅ | |
| [R](https://github.com/r-lib/tree-sitter-r) | | | |
| [Racket](https://github.com/6cdh/tree-sitter-racket) | | | |
| [Regex](https://github.com/tree-sitter/tree-sitter-regex) | | | |
| [Ruby](https://github.com/tree-sitter/tree-sitter-ruby) | ✅ | ✅ | ✅ |
| [Rust](https://github.com/tree-sitter/tree-sitter-rust) | | ✅ | ✅ |
| [Scala](https://github.com/tree-sitter/tree-sitter-scala) | | | |
| [Scheme](https://github.com/6cdh/tree-sitter-scheme) | | | |
| [Scss](https://github.com/serenadeai/tree-sitter-scss) | | | |
| [SQL](https://github.com/DerekStride/tree-sitter-sql) | | ✅ | ✅ |
| [Sqlite](https://github.com/dhcmrlchtdj/tree-sitter-sqlite) | | | |
| [SSH](https://github.com/metio/tree-sitter-ssh-client-config) | | ✅ | ✅ |
| [Swift](https://github.com/alex-pinkus/tree-sitter-swift/tree/with-generated-files) | ✅ | ✅ | ✅ |
| [TOML](https://github.com/tree-sitter/tree-sitter-toml) | | | |
| [Tree-sitter query language](https://github.com/nvim-treesitter/tree-sitter-query) | | ✅ | ✅ |
| [Typescript](https://github.com/tree-sitter/tree-sitter-typescript) | | | |
| [Verilog](https://github.com/tree-sitter/tree-sitter-verilog) | | | |
| [Vue](https://github.com/ikatyang/tree-sitter-vue) | | | |
| [YAML](https://github.com/mattmassicotte/tree-sitter-yaml/tree/feature/spm) | | ✅ | |
| [Zig](https://github.com/maxxnino/tree-sitter-zig) | ✅ | ✅ | ✅ |

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[build status]: https://github.com/ChimeHQ/SwiftTreeSitter/actions
[build status badge]: https://github.com/ChimeHQ/SwiftTreeSitter/workflows/CI/badge.svg
[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/SwiftTreeSitter
[platforms]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FSwiftTreeSitter%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
