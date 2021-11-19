# SwiftTreeSitter

Swift wrappers for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system. Remember that tree-sitter has both runtime and per-language dependencies. They all have to be installed and build separately.

## Integration

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
]
```

## Building Dependencies

SwiftTreeSitter needs the tree-sitter runtime libraries and headers. Your build configuration will, unfortunately, depend on how you want to package and distribute your final target. This is made even more complex because SPM currently does not allow you to select between a .dylib and .a **when both are in the same directory**. Static linking can simplify distribution, but SwiftTreeSitter should be compatible with both.

Ultimately, it could be that you cannot use this package without modification. I'd really prefer to make it more seamless, but I experimented with many different approaches, and this was the only one that offered sufficient flexibility. If you have other ideas, please get in touch.

Note: These instructions assume a macOS target. Also, I've only tested tree-sitter down to 10.13. I suspect it will work with lower targets, but have not tried.

### build

Check out and build tree-sitter from source. 

    CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" LDFLAGS="-mmacosx-version-min=10.13" make

### install

Install it into `/usr/local`. This is where the Swift.package expects it to be.

    sudo make install PREFIX=/usr/local

### remove the dylib

This **deletes** the dylib, so SPM links statically. I really wish this under the control of consumer of the package, but as far as I can tell, SPM does not support that.

    sudo rm /usr/local/lib/libtree-sitter*.dylib

## Building Language Libraries

In addition to the runtime, tree-sitter you'll probably also want at least one language library. These are more complex to build than the runtime, because each lib requires a small amount of patching. It's a real pain.

There's [hope](https://github.com/tree-sitter/tree-sitter-go/pull/56) that language libs will soon have an identical build process to the runtime! While still manual, it is at least more straightforward.

### check out the source

#### modify binding.gyp

An `xcode_settings` section needs to be added to `binding.gyp`. The `-isysroot` parameter could be unnecessary, depending on how your developer tools are installed/configured, and which SDK you want to build against.

And, again, I would imagine these libraries support macOS versions lower than 10.13, but I have not tried.

You should be able to use the [template](language-binding.gyp), replacing `tree_sitter_language_binding` with the language binding name.

### build

You need npm to build a language binding. Earlier versions of tree-sitter required a specific NPM version, but more recent versions are less picky. A standard NPM install should work.

    npm install

#### package and install

    ar rcs libtree-sitter-LANGUAGE.a build/Release/obj.target/tree_sitter_LANGUAGE_binding/src/*
    sudo cp libtree-sitter-LANGUAGE.a /usr/local/lib/

#### make a .h

To build against a language library, you'll need an .h file.

You can use the [template](language.h), replacing `TREE_SITTER_LANGUAGE_H_`, `tree_sitter_LANGUAGE`, and the file name as appropriate.

    sudo cp LANGUAGE.h /usr/local/include/tree_sitter/

#### make a .pc

This is useful when using SPM, but could be skipped if you are building/linking with another mechanism.

There's a [template](tree-sitter-LANGUAGE.pc) file for that as well. Remember to fill in `VERSION` and `language` as needed.

    sudo cp tree-sitter-changes/tree-sitter-LANGUAGE.pc /usr/local/lib/pkgconfig/

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
