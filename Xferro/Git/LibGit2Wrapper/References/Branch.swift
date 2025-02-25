//
//  Branch.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

/// A git branch.
struct Branch: Identifiable, ReferenceType, Hashable, Codable {
    var id: String { longName }
    /// The full name of the reference (e.g., `refs/heads/master`).
    let longName: String

    var wipName: String {
        name.replacingOccurrences(of: "/", with: "_")
    }

    /// The short human-readable name of the branch (e.g., `master`).
    let name: String

    /// A pointer to the referenced commit.
    let commit: PointerTo<Commit>

    // MARK: Derived Properties

    /// The short human-readable name of the branch (e.g., `master`).
    ///
    /// This is the same as `name`, but is declared with an Optional type to adhere to
    /// `ReferenceType`.
    var shortName: String? {
        if isRemote,
           let index = name.range(of: "/")?.upperBound {
            let shortname = name[index...]
            return String(shortname)
        }
        return name
    }

    /// The OID of the referenced object.
    ///
    /// This is the same as `commit.oid`, but is declared here to adhere to `ReferenceType`.
    var oid: OID { return commit.oid }

    var isLocal: Bool { return longName.isBranchRef }
    var isRemote: Bool { return longName.isRemoteRef }
    var isWip: Bool { return longName.isWipRef }
    /// Whether the branch is a unborn branch. If it is unborn, the oid will be invalid.
    var isUnborn: Bool = false

    var isSymbolic: Bool = false

    /// The remote repository name if this is a remote branch.
    var remoteName: String? {
        if isRemote {
            let name = longName.split(separator: "/")[2]
            return String(name)
        }
        return nil
    }

    /// Create an instance with a libgit2 `git_reference` object.
    ///
    /// Returns `nil` if the pointer isn't a branch.
    init?(_ pointer: OpaquePointer, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        longName = String(validatingCString: git_reference_name(pointer))!

        var namePointer: UnsafePointer<Int8>? = nil
        let success = git_branch_name(&namePointer, pointer)
        guard success == GIT_OK.rawValue else {
            return nil
        }
        name = String(validatingCString: namePointer!)!

        var oid: OID
        if git_reference_type(pointer).rawValue == GIT_REFERENCE_SYMBOLIC.rawValue {
            isSymbolic = true
            var resolved: OpaquePointer? = nil
            let success = git_reference_resolve(&resolved, pointer)
            guard success == GIT_OK.rawValue else {
                return nil
            }
            oid = OID(git_reference_target(resolved).pointee)
            git_reference_free(resolved)
        } else {
            oid = OID(git_reference_target(pointer).pointee)
        }
        commit = PointerTo<Commit>(oid)
    }
}
