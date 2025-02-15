//
//  WipWorktree.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Foundation

final class WipWorktree {
    static let wipBranchesPrefix = "com.xferro_wip_commits_"
    static let wipWorktreeFolder = "wip_worktrees"
    static let wipCommitMessage = "com.xferro.wip"
    let worktreeRepository: Repository
    let originalRepository: Repository

    static func worktreeName(for originalRepository: Repository) -> String {
        Self.worktreeRepositoryURL(originalRepository: originalRepository).path.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "/", with: "_")
    }

    static func get(for originalRepository: Repository) -> WipWorktree? {
        guard let worktreeRepository = originalRepository.worktree(named: worktreeName(for: originalRepository)).mustSucceed()
        else { return nil }
        return WipWorktree(worktreeRepository: worktreeRepository, originalRepository: originalRepository)
    }

    static func getOrCreate(for item: any SelectableItem) -> WipWorktree? {
        let worktreeRepositoryURL =  worktreeRepositoryURL(originalRepository: item.repository)
        let branchName = worktreeBranchName(item: item)

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

        let worktreeName = worktreeName(for: item.repository)
        if createRepoOID != nil {
            let worktreeRepository: Repository
            if let existingWorktreeRepository = item.repository.worktree(named: worktreeName).mustSucceed() {
                worktreeRepository = existingWorktreeRepository
            } else {
                let newBranch = item.repository.createBranch(branchName).mustSucceed()
                item.repository
                    .addWorkTree(
                        name: worktreeName,
                        path: worktreeRepositoryURL.path(percentEncoded: false)
                    ).mustSucceed()
                worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
                worktreeRepository.checkout(newBranch.longName).mustSucceed()
            }
            return WipWorktree(worktreeRepository: worktreeRepository, originalRepository: item.repository)
        } else if getRepoOID != nil {
            if let existingWorktreeRepository = item.repository.worktree(named: worktreeName).mustSucceed() {
                return WipWorktree(worktreeRepository: existingWorktreeRepository, originalRepository: item.repository)
            }
            else {
                return nil
            }
        } else {
            return nil
        }
    }

    private init(worktreeRepository: Repository, originalRepository: Repository) {
        self.worktreeRepository = worktreeRepository
        self.originalRepository = originalRepository
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
                "\(Self.wipBranchesPrefix)for_branch_\(branch.wipName)_commit_\(branch.commit.oid.description)"
            case .tag(_, let tag):
                "\(Self.wipBranchesPrefix)for_tag_\(tag.wipName)_commit_\(tag.oid.description)"
            case .detached(_, let commit):
                "\(Self.wipBranchesPrefix)for_detached_commit_\(commit.oid.description)"
            }
        case let commit as SelectableCommit:
            "\(Self.wipBranchesPrefix)for_branch_\(commit.branch.wipName)_commit_\(commit.oid.description)"
        case let detachedCommit as SelectableDetachedCommit:
            "\(Self.wipBranchesPrefix)for_detached_commit_\(detachedCommit.oid.description)"
        case let detachedTag as SelectableDetachedTag:
            "\(Self.wipBranchesPrefix)for_detached_tag_\(detachedTag.tag.wipName)_commit_\(detachedTag.oid.description)"
        case let tag as SelectableTag:
            "\(Self.wipBranchesPrefix)for_tag_\(tag.tag.wipName)_commit_\(tag.oid.description)"
        case let historyCommit as SelectableHistoryCommit:
            "\(Self.wipBranchesPrefix)for_branch_\(historyCommit.branch.wipName)_commit_\(historyCommit.oid.description)"
        case _ as SelectableWipCommit:
            fatalError(.illegal)
        default:
            fatalError(.unimplemented)
        }
    }

    func getBranch(branchName: String) -> Branch? {
        worktreeRepository.localBranch(named: branchName).mustSucceed()
    }

    @discardableResult
    func createBranch(branchName: String, oid: OID) -> Branch {
        worktreeRepository.createBranch(
            branchName,
            oid: oid,
            force: true
        ).mustSucceed()
    }

    func checkout(branchName: String) {
        worktreeRepository.checkout(branchName.longBranchRef,.init(strategy: .Force)).mustSucceed()
    }

    func addToWorktreeIndex(path: String) {
        worktreeRepository.add(path: path).mustSucceed()
    }

    @discardableResult
    func commit() -> Commit {
        worktreeRepository.commit(message: Self.wipCommitMessage).mustSucceed()
    }

    func commits(of branchName: String, stop: OID) -> [SelectableWipCommit] {
        guard let branch =  getBranch(branchName: branchName) else {
            fatalError("branch \(branchName) not found")
        }

        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: worktreeRepository, root: branch.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableWipCommit(repository: originalRepository, commit: commit))
            if commit.oid == stop {
                break
            }
        }
        return commits
    }
}
