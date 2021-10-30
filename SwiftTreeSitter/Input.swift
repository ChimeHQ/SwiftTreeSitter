//
//  Input.swift
//  SwiftTreeSitter
//
//  Created by Matt Massicotte on 2018-12-18.
//  Copyright © 2018 Chime Systems. All rights reserved.
//

import Foundation
import tree_sitter

class Input {
    typealias Buffer = UnsafeMutableBufferPointer<Int8>

    private let encoding: String.Encoding
    fileprivate let readBlock: Parser.ReadBlock
    private var internalBuffer: Buffer?

    init(encoding: String.Encoding, readBlock: @escaping Parser.ReadBlock) {
        self.encoding = encoding
        self.readBlock = readBlock
    }

    deinit {
        buffer = nil
    }

    fileprivate var buffer: Buffer? {
        get {
            return internalBuffer
        }
        set {
            if newValue == nil {
                internalBuffer?.deallocate()
            }

            internalBuffer = newValue
        }
    }

    fileprivate var bufferPointer: UnsafePointer<Int8>? {
        return buffer.flatMap { UnsafePointer<Int8>($0.baseAddress) }
    }

    var internalInput: TSInput? {
        guard let tsEncoding = encoding.internalEncoding else {
            return nil
        }

        let unmanaged = Unmanaged.passUnretained(self)

        return TSInput(payload: unmanaged.toOpaque(), read: readFunction, encoding: tsEncoding)
    }
}

private func readFunction(payload: UnsafeMutableRawPointer?, byteIndex: UInt32, position: TSPoint, bytesRead: UnsafeMutablePointer<UInt32>?) -> UnsafePointer<Int8>? {
    // get our self reference
    let wrapper: Input = Unmanaged.fromOpaque(payload!).takeUnretainedValue()

    // call our Swift-friendly reader block
    guard let data = wrapper.readBlock(Int(byteIndex), Point(internalPoint: position)) else {
        bytesRead?.pointee = 0
        return nil
    }

    // copy the data into an internally-managed buffer with a lifetime of wrapper
    let buffer = UnsafeMutableBufferPointer<Int8>.allocate(capacity: data.count)
    let copiedLength = data.copyBytes(to: buffer)
    precondition(copiedLength == data.count)

    wrapper.buffer = buffer

    // return to the caller
    bytesRead?.pointee = UInt32(buffer.count)

    return wrapper.bufferPointer
}
