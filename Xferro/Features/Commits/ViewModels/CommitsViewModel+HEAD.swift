//
//  CommitsViewModel+HEAD.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

extension CommitsViewModel {
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
    }

    func HEAD(for repository: Repository) -> CommitsViewModel.Head? {
        let getHead: (ReferenceType) -> CommitsViewModel.Head = { headRef in
            let head: CommitsViewModel.Head =
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
        guard let headRef = try? repository.HEAD().get() else { return nil }
        return getHead(headRef)
    }
}
