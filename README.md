# SwiftTreeSitter

Swift wrappers for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system. Remember that tree-sitter has both runtime and per-language dependencies. They all have to be installed and build separately.

## Integration

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
]
```

## Predicate Support

| Predicate | Readable | Supported |
| ----------|:--------:|:---------:|
| `eq?` | yes | yes |
| `match?`  | yes | yes |
| `is-not?`  | `local` only | no |

Query predicates are complex to support and have performance implications. Notably, `is-not? local` is **just** supported enough to be correctly read, but is not applied. Please open up an issue if you need additional support here.

## Building Dependencies

SwiftTreeSitter needs the tree-sitter runtime libraries and headers. Your build configuration will, unfortunately, depend on how you want to package and distribute your final target. This is made even more complex because SPM currently does not allow you to select between a .dylib and .a **when both are in the same directory**. Static linking can simplify distribution, but SwiftTreeSitter should be compatible with both.

Ultimately, it could be that you cannot use this package without modification. I'd really prefer to make it more seamless, but I experimented with many different approaches, and this was the only one that offered sufficient flexibility. If you have other ideas, please get in touch.

Note: These instructions assume a macOS target. Also, I've only tested tree-sitter down to 10.13. I suspect it will work with lower targets, but have not tried.

### build

Check out and build tree-sitter from source. 

    CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" CXXFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" LDFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" make

### install

Install it into `/usr/local`. This is where the Swift.package expects it to be.

    sudo make install PREFIX=/usr/local

### remove the dylib

This **deletes** the dylib, so SPM links statically. I really wish this was under the control of consumer of the package, but as far as I can tell, SPM does not support that.

    sudo rm /usr/local/lib/libtree-sitter*.dylib

## Building Language Libraries

In addition to the runtime, you'll probably also want at least one language library. These are more complex to build than the runtime. In fact, I've struggled with them so much that I began adapting the runtime's Makefile for the parsers themselves. This is a [work-in-progress](https://github.com/tree-sitter/tree-sitter/issues/1488). But, if the parser you'd like to use doesn't have a Makefile, let me know and I'll help get it set up.

And, if the parser does have a Makefile, then the process is identical to the runtime above.

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
