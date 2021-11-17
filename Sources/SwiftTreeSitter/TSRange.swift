//
//  TSRange.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2020-03-02.
//  Copyright © 2020 Example. All rights reserved.
//

import Foundation
import tree_sitter

public struct TSRange {
    public let points: Range<Point>
    public let bytes: Range<UInt32>

    public init(points: Range<Point>, bytes: Range<UInt32>) {
        self.points = points
        self.bytes = bytes
    }

    init(internalRange range: tree_sitter.TSRange) {
        self.bytes = range.start_byte..<range.end_byte
        self.points = Point(internalPoint: range.start_point)..<Point(internalPoint: range.end_point)
    }

    init(potentiallyInvalidRange range: tree_sitter.TSRange) {
        self.bytes = range.start_byte..<range.end_byte

        let start = Point(internalPoint: range.start_point)
        let end = Point(internalPoint: range.end_point)
        let safeEnd = start <= end ? end : start

        self.points = start..<safeEnd
    }
}

extension TSRange: Equatable {
}

extension TSRange: Comparable {
    public static func < (lhs: TSRange, rhs: TSRange) -> Bool {
        return lhs.points.lowerBound < rhs.points.lowerBound
    }
}
