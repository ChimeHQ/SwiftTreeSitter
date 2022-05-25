//
//  Node.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-17.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter

public struct Node {
    let internalNode: TSNode

    init?(internalNode: TSNode) {
        if ts_node_is_null(internalNode) {
            return nil
        }

        self.internalNode = internalNode
    }
}

extension Node: CustomDebugStringConvertible {
    public var debugDescription: String {
        let typeName = nodeType ?? "unnamed"

        return "<\(typeName) range: \(range) childCount: \(childCount)>"
    }
}

extension Node: Equatable {
    public static func == (lhs: Node, rhs: Node) -> Bool {
        return ts_node_eq(lhs.internalNode, rhs.internalNode)
    }
}

extension Node {
    public var sExpressionString: String? {
        guard let str = ts_node_string(internalNode) else {
            return nil
        }

        let string = String(cString: str)

        free(str)

        return string
    }

    public var nodeType: String? {
        guard let str = ts_node_type(internalNode) else {
            return nil
        }

        return String(cString: str)
    }

    public var symbol: Int {
        return Int(ts_node_symbol(internalNode))
    }

    public var range: NSRange {
        return byteRange.range
    }

    public var byteRange: Range<UInt32> {
        let start = ts_node_start_byte(internalNode)
        let end = ts_node_end_byte(internalNode)

        return start..<end
    }

    public var pointRange: Range<Point> {
        let start = ts_node_start_point(internalNode)
        let end = ts_node_end_point(internalNode)

        return Point(internalPoint: start)..<Point(internalPoint: end)
    }

    public var tsRange: TSRange {
        return TSRange(points: pointRange, bytes: byteRange)
    }

    public var childCount: Int {
        return Int(ts_node_child_count(internalNode))
    }

    public func child(at index: Int) -> Node? {
        let n = ts_node_child(internalNode, UInt32(index))

        return Node(internalNode: n)
    }

    public var parent: Node? {
        let n = ts_node_parent(internalNode)

        return Node(internalNode: n)
    }

    public var nextSibling: Node? {
        let n = ts_node_next_sibling(internalNode)

        return Node(internalNode: n)
    }

    public var previousSibling: Node? {
        let n = ts_node_prev_sibling(internalNode)

        return Node(internalNode: n)
    }

    public var nextNamedSibling: Node? {
        let n = ts_node_next_named_sibling(internalNode)

        return Node(internalNode: n)
    }

    public var previousNamedSibling: Node? {
        let n = ts_node_prev_named_sibling(internalNode)

        return Node(internalNode: n)
    }

    public func descendant(in pointRange: Range<Point>) -> Node? {
        let lower = pointRange.lowerBound
        let upper = pointRange.upperBound

        let n = ts_node_descendant_for_point_range(internalNode, lower.internalPoint, upper.internalPoint)

        return Node(internalNode: n)
    }

    public func descendant(in byteRange: Range<UInt32>) -> Node? {
        let lower = byteRange.lowerBound
        let upper = byteRange.upperBound

        let n = ts_node_descendant_for_byte_range(internalNode, lower, upper)
        
        return Node(internalNode: n)
    }
}

extension Node {
    public func enumerateChildren(block: (Node) -> Void) {
        for i in 0..<childCount {
            let n = child(at: i)!

            block(n)
        }
    }

    public var firstChild: Node? {
        if childCount == 0 {
            return nil
        }

        return child(at: 0)
    }
    
    public var lastChild: Node? {
        if childCount == 0 {
            return nil
        }

        return child(at: childCount - 1)
    }
    
    public var treeCursor: TreeCursor {
        let cursor = ts_tree_cursor_new(internalNode)

        return TreeCursor(internalCursor: cursor)
    }
}
