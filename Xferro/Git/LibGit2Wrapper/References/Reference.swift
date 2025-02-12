//
//  Reference.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

/// A generic reference to a git object.
struct Reference: ReferenceType, Hashable, Codable {
    /// The full name of the reference (e.g., `refs/heads/master`).
    let longName: String

    /// The short human-readable name of the reference if one exists (e.g., `master`).
    let shortName: String?

    /// The OID of the referenced object.
    let oid: OID

    /// Create an instance with a libgit2 `git_reference` object.
    init(_ pointer: OpaquePointer) {
        let shorthand = String(validatingCString: git_reference_shorthand(pointer))!
        longName = String(validatingCString: git_reference_name(pointer))!
        shortName = (shorthand == longName ? nil : shorthand)
        oid = OID(git_reference_target(pointer).pointee)
    }
}
