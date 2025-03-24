//
//  Tag.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

struct Tag: ObjectType, Hashable, Codable {
    static let type = GitObjectType.tag

    let oid: OID
    let target: Pointer
    let name: String
    let tagger: Signature
    let message: String

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
