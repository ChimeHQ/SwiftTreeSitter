import Foundation
import tree_sitter

/// Structure that describes a change to the text content.
///
/// Tree-sitter operates on byte indices and line/character-offset pairs (called a `Point`). The
/// byte offset calculations are required, but the Point values are optional. If you aren't going to
/// use line-relative positioning, do you not need to supply these values.
///
/// ```swift
/// let edit = InputEdit(startByte: editStartByteOffset,
///                      oldEndByte: preEditEndByteOffset,
///                      newEndByte: postEditEndByteOffset,
///                      startPoint: editStartPoint,
///                      oldEndPoint: preEditEndPoint,
///                      newEndPoint: postEditEndPoint)
///
/// // apply the edit first
/// existingTree.edit(edit)
///
/// // then, re-parse the text to build a new tree
/// let newTree = parser.parse(existingTree, string: fullText)
///
/// // you can now compute a diff to determine what has changed
/// let changedRanges = existingTree.changedRanges(newTree)
/// ```
public struct InputEdit: Hashable, Sendable {
    public let startByte: UInt32
    public let oldEndByte: UInt32
    public let newEndByte: UInt32
    public let startPoint: Point
    public let oldEndPoint: Point
    public let newEndPoint: Point

    public init(startByte: UInt32, oldEndByte: UInt32, newEndByte: UInt32, startPoint: Point, oldEndPoint: Point, newEndPoint: Point) {
        self.startByte = startByte
        self.oldEndByte = oldEndByte
        self.newEndByte = newEndByte
        self.startPoint = startPoint
        self.oldEndPoint = oldEndPoint
        self.newEndPoint = newEndPoint
    }

    public init(startByte: Int, oldEndByte: Int, newEndByte: Int, startPoint: Point, oldEndPoint: Point, newEndPoint: Point) {
        self.startByte = UInt32(startByte)
        self.oldEndByte = UInt32(oldEndByte)
        self.newEndByte = UInt32(newEndByte)
        self.startPoint = startPoint
        self.oldEndPoint = oldEndPoint
        self.newEndPoint = newEndPoint
    }

    var internalInputEdit: TSInputEdit {
        return TSInputEdit(start_byte: startByte,
                           old_end_byte: oldEndByte,
                           new_end_byte: newEndByte,
                           start_point: startPoint.internalPoint,
                           old_end_point: oldEndPoint.internalPoint,
                           new_end_point: newEndPoint.internalPoint)
    }
}
