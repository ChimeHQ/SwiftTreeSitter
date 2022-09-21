# ``SwiftTreeSitter``

Swift API for the tree-sitter incremental parsing system.

## Overview

SwiftTreeSitter attempts to map the [tree-sitter](https://tree-sitter.github.io/) C API very closely. It differs in two significant ways. First, it tries to use Swift/Foundation types when possible. And, it offers a much more featureful version of the ``QueryCursor`` object, ``ResolvingQueryCursor``. In all other respects, its best to refer to the C API for details and documentation.

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
- ``ResolvingQueryCursor``
- ``QueryCapture``
- ``QueryMatch``
- ``QueryError``
- ``Predicate``
- ``QueryPredicateError``
- ``QueryPredicateStep``

### Structures

- ``TSRange``
- ``Point``
