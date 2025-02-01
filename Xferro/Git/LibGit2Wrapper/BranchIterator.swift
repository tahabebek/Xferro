//
//  BranchIterator.swift
//  Xferro
//
//  Created by Taha Bebek on 1/31/25.
//

import Foundation

class BranchIterator: IteratorProtocol, Sequence {
    typealias Iterator = BranchIterator
    typealias Element = Result<Branch, NSError>

    enum IteratorType {
        case local, remote, all
    }

    let repo: Repository
    private var iterator: OpaquePointer?

    init(repo: Repository, type: IteratorType = .local) {
        self.repo = repo

        let flags = switch type {
        case .local:
            GIT_BRANCH_LOCAL
        case .remote:
            GIT_BRANCH_REMOTE
        case .all:
            GIT_BRANCH_ALL
        }

        git_branch_iterator_new(&iterator, repo.pointer, flags)
    }

    deinit {
        git_branch_iterator_free(iterator)
    }

    func next() -> Element? {
        let branchType = UnsafeMutablePointer<git_branch_t>.allocate(capacity: 1)
        var branch: OpaquePointer?
        defer {
            branchType.deallocate()
            if let branch {
                git_reference_free(branch)
            }
        }
        let result = Next(git_branch_next(&branch, branchType, iterator), name: "git_branch_next")
        switch result {
        case let .error(error):
            return .failure(error)
        case .over:
            return nil
        case .okay:
            return .success(Branch(branch!)!)
        }
    }
}
