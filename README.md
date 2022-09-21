[![Build Status][build status badge]][build status]
[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

# SwiftTreeSitter

Swift API for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system.

SwiftTreeSitter is fairly low-level. If you are looking a higher-level system for syntax highlighting and other syntactic operations, you might want to have a look at [Neon](https://github.com/ChimeHQ/Neon).

📖 [Documentation][documentation] is available in DocC format.

## Integration

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
]
```

## Language Parsers

Tree-sitter language parsers are separate projects, and you'll probably need at least one. More details are available in the [documentation][documentation].

| Language    | Offical Repo |
| --- | :---: |
| [Bash](https://github.com/lukepistrol/tree-sitter-bash/tree/feature/spm) | |
| [C](https://github.com/tree-sitter/tree-sitter-c) | ✅ |
| [C++](https://github.com/tree-sitter/tree-sitter-cpp) | ✅ |
| [C#](https://github.com/tree-sitter/tree-sitter-c-sharp) | ✅ |
| [CSS](https://github.com/lukepistrol/tree-sitter-css/tree/feature/spm) | |
| [Go](https://github.com/tree-sitter/tree-sitter-go) | |
| [GoMod](https://github.com/camdencheek/tree-sitter-go-mod) | |
| [HTML](https://github.com/mattmassicotte/tree-sitter-html/tree/feature/spm) | |
| [Java](https://github.com/tree-sitter/tree-sitter-java) | ✅ |
| [Javascript](https://github.com/tree-sitter/tree-sitter-javascript) | ✅ |
| [JSON](https://github.com/tree-sitter/tree-sitter-json) | ✅ |
| [Lua](https://github.com/Azganoth/tree-sitter-lua) | ✅ |
| [Markdown](https://github.com/mattmassicotte/tree-sitter-markdown-2/tree/feature/spm) | |
| [PHP](https://github.com/tree-sitter/tree-sitter-php) | ✅ |
| [Python](https://github.com/lukepistrol/tree-sitter-python/tree/feature/spm) | |
| [Ruby](https://github.com/tree-sitter/tree-sitter-ruby) | ✅ |
| [Rust](https://github.com/tree-sitter/tree-sitter-rust) | ✅ |
| [Swift](https://github.com/alex-pinkus/tree-sitter-swift/tree/with-generated-files) | ✅ |
| [YAML](https://github.com/mattmassicotte/tree-sitter-yaml/tree/feature/spm) | |

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
