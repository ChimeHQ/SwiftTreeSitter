# ``SwiftTreeSitter``

Swift API for the tree-sitter incremental parsing system.

## Overview

SwiftTreeSitter attempts to map the [tree-sitter](https://tree-sitter.github.io/) C API very closely. It differs in two significant ways. First, it tries to use Swift/Foundation types when possible. And, it offers a query resolution system based around ``ResolvingQueryMatchSequence``.

In all other respects, it's best to refer to the C API for details and documentation.

## Topics

### Parsing

- <doc:New-Languages>
- <doc:Using-Tree-Sitter>
- ``Parser``
- ``Language``
- ``InputEdit``

### Trees

- ``Tree``
- ``Node``
- ``TreeCursor``

### Queries

- ``Query``
- ``QueryCursor``
- ``ResolvingQueryMatchSequence``
- ``QueryCapture``
- ``QueryMatch``
- ``QueryError``
- ``Predicate``
- ``QueryPredicateError``
- ``QueryPredicateStep``

### Structures

- ``TSRange``
- ``Point``
