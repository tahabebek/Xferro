//
//  Blob.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

/// A git blob.
struct Blob: ObjectType, Hashable {
    static let type = GitObjectType.blob

    /// The OID of the blob.
    let oid: OID

    /// The contents of the blob.
    let data: Data

    let dataSize: UInt
    let isBinary: Bool
    let pointer: OpaquePointer

    /// Create an instance with a libgit2 `git_blob`.
    init(_ pointer: OpaquePointer, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        oid = OID(git_object_id(pointer).pointee)
        let length = Int(git_blob_rawsize(pointer))
        data = Data(bytes: git_blob_rawcontent(pointer), count: length)
        dataSize = UInt(git_blob_rawsize(pointer))
        isBinary =  (git_blob_is_binary(pointer) != 0)
        self.pointer = pointer
    }

    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
    {
        try body(.init(
            start: git_blob_rawcontent(pointer),
            count: Int(git_blob_rawsize(pointer)
                      )))
    }
}

////
