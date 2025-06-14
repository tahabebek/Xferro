//
//  UnbornBranch.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

struct UnbornBranch: BaseReferenceType {

    /// The full name of the reference (e.g., `refs/heads/master`).
    var longName: String

    /// The short human-readable name of the reference if one exists (e.g., `master`).
    var shortName: String? {
        return name
    }

    var name: String

    /// Create an instance with a libgit2 `git_reference` object.
    ///
    /// Returns `nil` if the pointer isn't a branch.
    init?(_ pointer: OpaquePointer, unborn: Bool = false, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        longName = String(validatingCString: git_reference_symbolic_target(pointer))!
        name = longName.split(separator: "/")[2...].joined(separator: "/")
    }
}
