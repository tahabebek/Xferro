//
//  WipWorktree.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Foundation

final class WipWorktree {
    static let wipBranchesPrefix = "_xferro_wip_commits_"
    static let wipWorktreeFolder = "wip_worktrees"
    private let worktreeRepository: Repository
    let initialBranchName: String
    let initialCommit: OID

    static func create(
        originalRepositoryWithNoCommits originalRepository: Repository,
        initialWorktreeBranchName: String
    ) -> WipWorktree {
        let worktreeRepositoryURL = worktreeRepositoryURL(originalRepository: originalRepository)
        let worktreeRepository: Repository
        let oid: OID
        if Repository.isGitRepository(url: worktreeRepositoryURL).mustSucceed() {
            worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
            guard worktreeRepository.isWorkTree else {
                fatalError(.illegal)
            }
            guard let head = try? worktreeRepository.commit().get() else {
                fatalError("Could not get head commit for existing worktree repository \(worktreeRepository)")
            }
            oid = head.oid
        } else {
            let emptyCommit =  originalRepository.createEmptyCommit()
            originalRepository
                .addWorkTree(
                    name: initialWorktreeBranchName,
                    path: worktreeRepositoryURL.path(percentEncoded: false)
                ).mustSucceed()
            worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
            if !worktreeRepository.localBranchExists(named: initialWorktreeBranchName).mustSucceed() {
                _ = worktreeRepository.createBranch(
                    initialWorktreeBranchName,
                    oid: emptyCommit.oid,
                    force: true
                ).mustSucceed()
            }
            worktreeRepository.checkout(initialWorktreeBranchName.longBranchRef,.init(strategy: .Force)).mustSucceed()
            oid = emptyCommit.oid
        }

        return WipWorktree(
                worktreeRepository: worktreeRepository,
                initialBranchName: initialWorktreeBranchName,
                initialCommit: oid
        )
    }

    static func create(for item: any SelectableItem) -> WipWorktree? {
        let worktreeRepositoryURL =  worktreeRepositoryURL(originalRepository: item.repository)
        let initialWorktreeBranchName = worktreeBranchName(item: item)

        if let status = item as? SelectableStatus {
            if case .noCommit = status.type {
                return create(originalRepositoryWithNoCommits: item.repository, initialWorktreeBranchName: initialWorktreeBranchName)
            }
        }
        let head =  item.repository.HEAD().mustSucceed()
        var createRepoOID: OID?
        var getRepoOID: OID?
        switch item {
        case _ as SelectableStatus:
            createRepoOID = head.oid
        case let commit as SelectableCommit:
            if commit.oid == head.oid {
                createRepoOID = head.oid
            } else {
                getRepoOID = commit.oid
            }
        case let detachedCommit as SelectableDetachedCommit:
            if detachedCommit.oid == head.oid {
                createRepoOID = head.oid
            } else {
                getRepoOID = detachedCommit.oid
            }
        case let detachedTag as SelectableDetachedTag:
            if detachedTag.oid == head.oid {
                createRepoOID = head.oid
            } else {
                getRepoOID = detachedTag.oid
            }
        case let tag as SelectableTag:
            if tag.oid == head.oid {
                createRepoOID = head.oid
            } else {
                getRepoOID = tag.oid
            }
        case let historyCommit as SelectableHistoryCommit:
            if historyCommit.oid == head.oid {
                createRepoOID = head.oid
            } else {
                getRepoOID = historyCommit.oid
            }
        case _ as SelectableWipCommit:
            fatalError(.unsupported)
        default:
            fatalError(.unimplemented)
        }

        if let createRepoOID {
            let worktreeRepository: Repository
            if Repository.isGitRepository(url: worktreeRepositoryURL).mustSucceed() {
                worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
                guard worktreeRepository.isWorkTree else {
                    fatalError(.illegal)
                }
                guard let head = try? worktreeRepository.commit().get() else {
                    fatalError("Could not get head commit for existing worktree repository \(worktreeRepository)")
                }
            } else {
                item.repository
                    .addWorkTree(
                        name: initialWorktreeBranchName,
                        path: worktreeRepositoryURL.path(percentEncoded: false)
                    ).mustSucceed()
                worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
            }

            if !worktreeRepository.localBranchExists(named: initialWorktreeBranchName).mustSucceed() {
                _ = worktreeRepository.createBranch(
                    initialWorktreeBranchName,
                    oid: createRepoOID,
                    force: true
                ).mustSucceed()
            }
            worktreeRepository.checkout(initialWorktreeBranchName.longBranchRef,.init(strategy: .Force)).mustSucceed()
            return WipWorktree(
                worktreeRepository: worktreeRepository,
                initialBranchName: initialWorktreeBranchName,
                initialCommit: head.oid
            )
        } else if let getRepoOID {
            if Repository.isGitRepository(url: worktreeRepositoryURL).mustSucceed() {
                let worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
                guard worktreeRepository.isWorkTree else {
                    fatalError(.illegal)
                }
                guard let head = try? worktreeRepository.commit().get() else {
                    fatalError("Could not get head commit for existing worktree repository \(worktreeRepository)")
                }
                return WipWorktree(
                    worktreeRepository: worktreeRepository,
                    initialBranchName: initialWorktreeBranchName,
                    initialCommit: head.oid
                )
            }
            else {
                return nil
            }
        } else {
            return nil
        }
    }

    private init(
        worktreeRepository: Repository,
        initialBranchName: String,
        initialCommit: OID
    ) {
        self.worktreeRepository = worktreeRepository
        self.initialBranchName = initialBranchName
        self.initialCommit = initialCommit
    }

    static func worktreeRepositoryURL(originalRepository: Repository)  -> URL {
        let originalRepositoryPath =  originalRepository.gitDir.deletingLastPathComponent().path()

        let worktreeRepositoryURL = DataManager.appDir.appendingPathComponent(Self.wipWorktreeFolder).appendingPathComponent(String(originalRepositoryPath.dropFirst()))
        try? FileManager.default.createDirectory(
            at: worktreeRepositoryURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        return worktreeRepositoryURL
    }

    static func worktreeBranchName(item: any SelectableItem) -> String {
        return switch item {
        case let status as SelectableStatus:
            switch status.type {
            case .branch(_, let branch):
                "\(Self.wipBranchesPrefix)for_branch_\(branch.longName.replacingOccurrences(of: "/", with: "_"))_commit_\(branch.commit.oid.description)"
            case .tag(_, let tag):
                "\(Self.wipBranchesPrefix)for_tag_\(tag.longName.replacingOccurrences(of: "/", with: "_"))_commit_\(tag.oid.description)"
            case .detached(_, let commit):
                "\(Self.wipBranchesPrefix)for_detached_commit_\(commit.oid.description)"
            case .noCommit:
                "\(Self.wipBranchesPrefix)for_no_commit"
            }
        case let commit as SelectableCommit:
            "\(Self.wipBranchesPrefix)for_branch_\(commit.branch.longName.replacingOccurrences(of: "/", with: "_"))_commit_\(commit.oid.description)"
        case let detachedCommit as SelectableDetachedCommit:
            "\(Self.wipBranchesPrefix)for_detached_commit_\(detachedCommit.oid.description)"
        case let detachedTag as SelectableDetachedTag:
            "\(Self.wipBranchesPrefix)for_tag_\(detachedTag.tag.longName.replacingOccurrences(of: "/", with: "_"))_commit_\(detachedTag.oid.description)"
        case let tag as SelectableTag:
            "\(Self.wipBranchesPrefix)for_tag_\(tag.tag.longName.replacingOccurrences(of: "/", with: "_"))_commit_\(tag.oid.description)"
        case let historyCommit as SelectableHistoryCommit:
            "\(Self.wipBranchesPrefix)for_branch_\(historyCommit.branch.longName.replacingOccurrences(of: "/", with: "_"))_commit_\(historyCommit.oid.description)"
        case _ as SelectableWipCommit:
            fatalError(.illegal)
        default:
            fatalError(.unimplemented)
        }
    }

    func getBranch(branchName: String) -> Branch? {
        if worktreeRepository.localBranchExists(named: branchName).mustSucceed() {
            return worktreeRepository.localBranch(named: branchName).mustSucceed()
        }
        return nil
    }

    func addToWorktreeIndex(path: String) {
         worktreeRepository.add(path: path).mustSucceed()
    }

    func commit() {
        var head: OpaquePointer?
        var commit: OpaquePointer?
        git_repository_head(&head, worktreeRepository.pointer)
        let peelResult = withUnsafeMutablePointer(to: &commit) { commitPtr in
            git_reference_peel(commitPtr, head, GIT_OBJECT_COMMIT)
        }
        guard peelResult == GIT_OK.rawValue else {
            fatalError()
        }

        let signiture = Signature.default(worktreeRepository).mustSucceed().makeUnsafeSignature().mustSucceed()
        defer { git_signature_free(signiture) }
        let index = worktreeRepository.unsafeIndex().mustSucceed()
        defer { git_index_free(index) }
        let _ = worktreeRepository.commit(
            index: index,
            parentCommits: [commit],
            message: "Wip commit",
            signature: signiture
        ).mustSucceed()
    }

    func commits(of item : any SelectableItem) -> [SelectableWipCommit] {
        let branchName = Self.worktreeBranchName(item: item)
        guard let branch =  getBranch(branchName: branchName) else {
            fatalError("branch \(branchName) not found")
        }

        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: worktreeRepository, root: branch.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableWipCommit(repository: worktreeRepository, commit: commit))
            if commit.oid == item.oid {
                break
            }
        }
        return commits
    }
}
