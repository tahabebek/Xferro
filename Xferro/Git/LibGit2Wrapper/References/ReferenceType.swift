//
//  References.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

/// A reference to a git object.
protocol BaseReferenceType {
    /// The full name of the reference (e.g., `refs/heads/master`).
    var longName: String { get }

    /// The short human-readable name of the reference if one exists (e.g., `master`).
    var shortName: String? { get }
}

/// A reference to a git object.
protocol ReferenceType: BaseReferenceType {
    /// The OID of the referenced object.
    var oid: OID { get }
}

extension ReferenceType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.longName == rhs.longName
        && lhs.oid == rhs.oid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(longName)
        hasher.combine(oid)
    }
}

/// Create a Reference, Branch, or TagReference from a libgit2 `git_reference`.
 func referenceWithLibGit2Reference(_ pointer: OpaquePointer) -> ReferenceType {
    if git_reference_is_branch(pointer) != 0 || git_reference_is_remote(pointer) != 0 {
        return Branch(pointer)!
    } else if git_reference_is_tag(pointer) != 0 {
        return TagReference(pointer)!
    } else {
        return Reference(pointer)
    }
}
