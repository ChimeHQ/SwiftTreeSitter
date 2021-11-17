//
//  InputEdit.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-18.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter

public struct InputEdit {
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

    var internalInputEdit: TSInputEdit {
        return TSInputEdit(start_byte: startByte,
                           old_end_byte: oldEndByte,
                           new_end_byte: newEndByte,
                           start_point: startPoint.internalPoint,
                           old_end_point: oldEndPoint.internalPoint,
                           new_end_point: newEndPoint.internalPoint)
    }
}
