# Adding Language Parsers

Parsers are separate projects that are required to work with a language.

## Overview

SwiftTreeSitter is largely a wrapper around the tree-sitter runtime API. On its own, it cannot parse anything. The runtime must be combined with a parser project made for a specific language grammar. If you are interested in using tree-sitter, you'll probably need at least one parser.

They can be built manually or integrated with SPM.

> Important: The tree-sitter system is used by many other projects. Please commit parsers improvements back to their main repositories.

### Using SPM

If you're using Swift, you'll probably be most interested in using SPM for your parser dependencies. This is probably the most convenient option, but may require adding SPM support to the parser. If you are adding SPM support to a language, we can list your temporary fork in the README.

For an example of the changes needed, see [this PR](https://github.com/tree-sitter/tree-sitter-java/pull/113).

## Building Manually

One option is just to build parser manually. This is typically done with node. Interfacing the resulting outputs with Swift will typically involve writing a custom C header file, using `ar` to build a static library, and then laying everything out with a `Module.modulemap` file. It's laborious, but possible.

### Using Make

I was so frustrated with the manual build process, that I began [adapting](https://github.com/tree-sitter/tree-sitter/issues/1488) the runtime's Makefile to the parsers. Only a handful are done. But, if you want to proceed with a custom build, I would recommend taking the time to do this.

The process is now dialed in enough that nearly all aspects of the Make system are parser-generic. You really just need to drop in some files and open a pull request on the main parser repository.

For an example of the changes needed, see [this PR](https://github.com/tree-sitter/tree-sitter-java/pull/110).
