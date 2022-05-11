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

## Runtime/Parser Dependencies

Remember that tree-sitter has both runtime and per-language dependencies.

This library has gone through a variety of iterations on how these dependencies should be integrated. The [tree-sitter-xcframework](https://github.com/krzyzanowskim/tree-sitter-xcframework) was created to help package everything up in a way that was totally transparent.

However, it turns out that it is possible to use SPM to build the runtime and (with a little more work) the parsers too. SwiftTreeSitter currently depends on a branch I created for tree-sitter as an SPM package. But as soon as [this PR](https://github.com/tree-sitter/tree-sitter/pull/1736) is merged, it can be switched to the official repo directly.

## Language Parsers

In addition to the runtime, you'll probably also want at least one language library. They can also be built with SPM, though they are more complex. If you would like SPM support for parser that doesn't have it yet, let me know and I'll help!

Parsers available via SPM:

- [Go](https://github.com/mattmassicotte/tree-sitter-go/tree/feature/swift)
- [GoMod](https://github.com/mattmassicotte/tree-sitter-go-mod/tree/feature/swift)
- [JSON](https://github.com/mattmassicotte/tree-sitter-json/tree/feature/spm)
- [Ruby](https://github.com/mattmassicotte/tree-sitter-ruby/tree/feature/swift)
- [Swift](https://github.com/mattmassicotte/tree-sitter-swift/tree/feature/spm)

While SPM is nice, it isn't a requirement. You can also build them yourself directly. In fact, I've struggled with this so much that I began adapting the runtime's Makefile for the parsers themselves. This is a [work-in-progress](https://github.com/tree-sitter/tree-sitter/issues/1488). But, if the parser you'd like to use doesn't have a Makefile, let me know and I'll help get it set up.

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

Please open up an issue if you need additional support here.

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[build status]: https://github.com/ChimeHQ/SwiftTreeSitter/actions
[build status badge]: https://github.com/ChimeHQ/SwiftTreeSitter/workflows/CI/badge.svg
[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/SwiftTreeSitter
[platforms]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FSwiftTreeSitter%2Fbadge%3Ftype%3Dplatforms
