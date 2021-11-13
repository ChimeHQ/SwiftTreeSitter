//
//  Tree.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-17.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter

public class Tree {
    let internalTree: OpaquePointer

    init(internalTree: OpaquePointer) {
        self.internalTree = internalTree
    }

    deinit {
        ts_tree_delete(internalTree)
    }
}

extension Tree {
    public var rootNode: Node? {
        let node = ts_tree_root_node(internalTree)

        return Node(internalNode: node)
    }
}

extension Tree {
    public func edit(_ inputEdit: InputEdit) {
        withUnsafePointer(to: inputEdit.internalInputEdit) { (ptr) -> Void in
            ts_tree_edit(internalTree, ptr)
        }
    }

    public func changedRanges(from other: Tree) -> [TSRange] {
        var count: UInt32 = 0

        guard let tsRanges = ts_tree_get_changed_ranges(internalTree, other.internalTree, &count) else {
            return []
        }

        let bufferPointer = UnsafeBufferPointer(start: tsRanges, count: Int(count))

        // there is a bug in the current tree sitter version
        // that can produce ranges with invalid points (but seemingly correct) byte
        // offsets. We have to be more careful with those.
        let ranges = bufferPointer.map({ TSRange(potentiallyInvalidRange: $0) })

        free(tsRanges)

        return ranges
    }
}

extension Tree {
    public func enumerateNodes(in byteRange: Range<UInt32>, block: (Node) throws -> Void) rethrows {
        guard let root = rootNode else { return }

        guard let node = root.descendant(in: byteRange) else { return }

        try block(node)

        let cursor = node.treeCursor

        if cursor.goToFirstChild(for: byteRange.lowerBound) == false {
            return
        }

        try cursor.enumerateCurrentAndDescendents(block: block)

        while cursor.gotoNextSibling() {
            guard let node = cursor.currentNode else {
                assertionFailure("no current node when gotoNextSibling succeeded")
                break
            }

            // once we are past the interesting range, stop
            if node.byteRange.lowerBound > byteRange.upperBound {
                break
            }

            try cursor.enumerateCurrentAndDescendents(block: block)
        }
    }
}
