//
//  Tag.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

/// An annotated git tag.
struct Tag: ObjectType, Hashable, Codable {
    static let type = GitObjectType.tag

    /// The OID of the tag.
    let oid: OID

    /// The tagged object.
    let target: Pointer

    /// The name of the tag.
    let name: String

    /// The tagger (author) of the tag.
    let tagger: Signature

    /// The message of the tag.
    let message: String

    /// Create an instance with a libgit2 `git_tag`.
    init(_ pointer: OpaquePointer, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        oid = OID(git_object_id(pointer).pointee)
        let targetOID = OID(git_tag_target_id(pointer).pointee)
        target = Pointer(oid: targetOID, type: git_tag_target_type(pointer))!
        name = String(validatingCString: git_tag_name(pointer))!
        tagger = Signature(git_tag_tagger(pointer).pointee)
        message = String(validatingCString: git_tag_message(pointer))!
    }
}
