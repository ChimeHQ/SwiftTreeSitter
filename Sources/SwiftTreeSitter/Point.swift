//
//  Point.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-18.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter

public struct Point {
    public let row: UInt32
    public let column: UInt32

    public init(row: UInt32, column: UInt32) {
        self.row = row
        self.column = column
    }

    public init(row: Int, column: Int) {
        self.row = UInt32(row)
        self.column = UInt32(column)
    }

    init(internalPoint: TSPoint) {
        self.row = internalPoint.row
        self.column = internalPoint.column
    }

    var internalPoint: TSPoint {
        return TSPoint(row: row, column: column)
    }
}

extension Point: Comparable {
    public static func < (lhs: Point, rhs: Point) -> Bool {
        if lhs.row < rhs.row {
            return true
        } else if lhs.row > rhs.row {
            return false
        } else {
            return lhs.column < rhs.column
        }
    }
}

extension Point: CustomStringConvertible {
    public var description: String {
        return "{\(row), \(column)}"
    }
}
extension Point: Hashable {
}

extension Point {
    public static let zero = Point(row: 0, column: 0)
}
