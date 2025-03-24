//
//  Branch.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

struct Branch: Identifiable, ReferenceType, Hashable, Codable {
    var id: String { longName }
    let longName: String
    var wipName: String {
        name.replacingOccurrences(of: "/", with: "_")
    }

    /// The short human-readable name of the branch (e.g., `master`).
    let name: String

    let commit: PointerTo<Commit>

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

    var oid: OID { return commit.oid }
    var isLocal: Bool { return longName.isBranchRef }
    var isRemote: Bool { return longName.isRemoteRef }
    var isWip: Bool { return longName.isWipRef }
    var isUnborn: Bool = false
    var isSymbolic: Bool = false
    var remoteName: String? {
        if isRemote {
            let name = longName.split(separator: "/")[2]
            return String(name)
        }
        return nil
    }

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
