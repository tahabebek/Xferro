//
//  CommitIterator.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

enum Next {
    case over
    case okay
    case error(NSError)

    init(_ result: Int32, name: String) {
        switch result {
        case GIT_ITEROVER.rawValue:
            self = .over
        case GIT_OK.rawValue:
            self = .okay
        default:
            self = .error(NSError(gitError: result, pointOfFailure: name))
        }
    }
}


class CommitIterator: IteratorProtocol, Sequence {
    typealias Iterator = CommitIterator
    typealias Element = Result<Commit, NSError>
    let repo: Repository
    private var revisionWalker: OpaquePointer?

    init(repo: Repository, root: git_oid, reversed: Bool = false) {
        self.repo = repo
        setupRevisionWalker(root: root, reversed: reversed)
    }

    deinit {
        git_revwalk_free(self.revisionWalker)
    }

    private func setupRevisionWalker(root: git_oid, reversed: Bool = false) {
        repo.lock.lock()
        defer { repo.lock.unlock() }
        var oid = root
        git_revwalk_new(&revisionWalker, repo.pointer)
        if reversed {
            git_revwalk_sorting(
                revisionWalker,
                GIT_SORT_TOPOLOGICAL.rawValue | GIT_SORT_TIME.rawValue | GIT_SORT_REVERSE.rawValue
            )
        } else {
            git_revwalk_sorting(revisionWalker, GIT_SORT_TOPOLOGICAL.rawValue | GIT_SORT_TIME.rawValue)
        }
        git_revwalk_push(revisionWalker, &oid)
    }

    func next() -> Element? {
        repo.lock.lock()
        defer { repo.lock.unlock() }
        var oid = git_oid()
        let revwalkGitResult = git_revwalk_next(&oid, revisionWalker)
        let nextResult = Next(revwalkGitResult, name: "git_revwalk_next")
        switch nextResult {
        case let .error(error):
            return Result.failure(error)
        case .over:
            return nil
        case .okay:
            var unsafeCommit: OpaquePointer? = nil
            let lookupGitResult = git_commit_lookup(&unsafeCommit, repo.pointer, &oid)
            guard lookupGitResult == GIT_OK.rawValue,
                  let unwrapCommit = unsafeCommit else {
                return Result.failure(NSError(gitError: lookupGitResult, pointOfFailure: "git_commit_lookup"))
            }
            let result: Element = Result.success(Commit(unwrapCommit, lock: repo.lock))
            git_commit_free(unsafeCommit)
            return result
        }
    }
}
