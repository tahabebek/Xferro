//
//  Objects.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

enum GitObjectType: Int32 {
    case any         = -2 /**< GIT_OBJECT_ANY, Object can be any of the following */
    case invalid     = -1 /**< GIT_OBJECT_INVALID, Object is invalid. */
    case commit      = 1 /**< GIT_OBJECT_COMMIT, A commit object. */
    case tree        = 2 /**< GIT_OBJECT_TREE, A tree (directory listing) object. */
    case blob        = 3 /**< GIT_OBJECT_BLOB, A file revision object. */
    case tag         = 4 /**< GIT_OBJECT_TAG, An annotated tag object. */
    case offsetDelta = 6 /**< GIT_OBJECT_OFS_DELTA, A delta, base is given by an offset. */
    case refDelta    = 7 /**< GIT_OBJECT_REF_DELTA, A delta, base is given by object id. */

    var git_type: git_object_t {
        return git_object_t(rawValue: self.rawValue)
    }
}

protocol ObjectType {
    static var type: GitObjectType { get }

    var oid: OID { get }
    init(_ pointer: OpaquePointer, lock: NSRecursiveLock)
}

extension ObjectType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.oid == rhs.oid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
    }
}
