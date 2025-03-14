//
//  GitBuffer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import Foundation

final class GitBuffer {
    var buffer: git_buf
    private let pointer: UnsafeMutablePointer<Int8>

    init(size: Int) {
        self.pointer = UnsafeMutablePointer<Int8>.allocate(capacity: size)
        self.buffer = git_buf(ptr: pointer, reserved: 0, size: size)
        self.pointer.initialize(repeating: 0, count: size)
    }

    deinit {
        pointer.deallocate()
    }
}
