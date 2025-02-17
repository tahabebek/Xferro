//
//  HEAD.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

enum Head: Codable {
    case branch(Branch)
    case tag(TagReference)
    case reference(Reference)

    var oid: OID {
        switch self {
        case .branch(let branch):
            return branch.oid
        case .tag(let tagReference):
            return tagReference.oid
        case .reference(let reference):
            return reference.oid
        }
    }

    static func of(_ repository: Repository) -> Head {
        let getHead: (ReferenceType) -> Head = { headRef in
            let head: Head =
            if let branchRef = headRef as? Branch {
                .branch(branchRef)
            } else if let tagRef = headRef as? TagReference {
                .tag(tagRef)
            } else if let reference = headRef as? Reference {
                .reference(reference)
            } else {
                fatalError(.impossible)
            }
            return head

        }
        guard let headRef = try? repository.HEAD().get() else {
            fatalError("You must create a head for every repository")
        }
        return getHead(headRef)
    }

    static func of(worktree: String, in repository: Repository) -> Head {
        let getHead: (ReferenceType) -> Head = { headRef in
            let head: Head =
            if let branchRef = headRef as? Branch {
                .branch(branchRef)
            } else if let tagRef = headRef as? TagReference {
                .tag(tagRef)
            } else if let reference = headRef as? Reference {
                .reference(reference)
            } else {
                fatalError(.impossible)
            }
            return head
        }
        guard let headRef = try? repository.HEAD(for: worktree).get() else {
            fatalError("Worktree \(worktree) doesn't have a head.")
        }
        return getHead(headRef)
    }
}

