//
//  WorktreeHelper.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Foundation

struct Worktree {
    static let wipBranchesPrefix = "_xferro_wip_commits_"
    static let wipWorktreeFolder = "wip_worktrees"
    let originalRepository: Repository
    let worktreeRepository: Repository
    let initialBranchName: String
    let initialCommit: OID

    private init(
        originalRepository: Repository,
        worktreeRepository: Repository,
        initialBranchName: String,
        initialCommit: OID
    ) {
        self.originalRepository = originalRepository
        self.worktreeRepository = worktreeRepository
        self.initialBranchName = initialBranchName
        self.initialCommit = initialCommit
    }

    init?(originalRepositoryWithNoCommits originalRepository: Repository, initialWorktreeBranchName: String) {
        guard let worktreeRepositoryURL = Self.worktreeRepositoryURL(originalRepository: originalRepository) else { return nil }
        if let existingWorktreeRepository = Self.getWorktreeRepository(worktreeRepositoryURL: worktreeRepositoryURL) {
            guard let head = try? existingWorktreeRepository.commit().get() else {
                fatalError("Could not get head commit for existing worktree repository \(existingWorktreeRepository)")
            }
            self.init(
                originalRepository: originalRepository,
                worktreeRepository: existingWorktreeRepository,
                initialBranchName: initialWorktreeBranchName,
                initialCommit: head.oid
            )
        } else {
            let emptyCommit = originalRepository.createEmptyCommit()
            originalRepository
                .addWorkTree(
                    name: initialWorktreeBranchName,
                    path: worktreeRepositoryURL.path(percentEncoded: false)
                ).mustSucceed()
            let worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
            Self.checkoutOrCreateAndCheckoutBranchOfWorktreeIfNeeded(
                worktreeRepository: worktreeRepository,
                branchName: initialWorktreeBranchName,
                initialCommit: emptyCommit.oid
            )
            self.init(
                originalRepository: originalRepository,
                worktreeRepository: worktreeRepository,
                initialBranchName: initialWorktreeBranchName,
                initialCommit: emptyCommit.oid
            )
        }
    }

    init?(of item: any SelectableItem) {
        guard let worktreeRepositoryURL = Self.worktreeRepositoryURL(originalRepository: item.repository) else { return nil }
        let initialWorktreeBranchName = Self.worktreeBranchName(item: item)

        if let status = item as? SelectableStatus {
            if case .noCommit = status.type {
                guard let worktree = Worktree(
                    originalRepositoryWithNoCommits: item.repository,
                    initialWorktreeBranchName: initialWorktreeBranchName
                ) else { return nil }
                self = worktree
                return
            }
        }
        let head = item.repository.HEAD().mustSucceed()
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
            return nil
        default:
            fatalError()
        }

        if let createRepoOID {
            let worktreeRepository = Self.createWorktreeRepositoryIfNeeded(
                originalRepository: item.repository,
                initialWorktreeBranchName: initialWorktreeBranchName,
                worktreeRepositoryURL: worktreeRepositoryURL
            )
            Self.checkoutOrCreateAndCheckoutBranchOfWorktreeIfNeeded(
                worktreeRepository: worktreeRepository,
                branchName: initialWorktreeBranchName,
                initialCommit: createRepoOID
            )
            self = Worktree(
                originalRepository: item.repository,
                worktreeRepository: worktreeRepository,
                initialBranchName: initialWorktreeBranchName,
                initialCommit: head.oid
            )
        } else if let getRepoOID {
            if let worktreeRepository = Self.getWorktreeRepository(worktreeRepositoryURL: worktreeRepositoryURL) {
                self = Worktree(
                    originalRepository: item.repository,
                    worktreeRepository: worktreeRepository,
                    initialBranchName: initialWorktreeBranchName,
                    initialCommit: getRepoOID
                )
            } else { return nil }
        } else { return nil }
    }

    static func worktreeRepositoryURL(originalRepository: Repository) -> URL? {
        guard let originalRepositoryPath = originalRepository.gitDir?.deletingLastPathComponent().path() else {
            return nil
        }

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

    static func getWorktreeRepository(
        worktreeRepositoryURL: URL
    ) -> Repository? {
        guard let worktreeRepository = try? Repository.at(worktreeRepositoryURL).get() else { return nil }
        guard worktreeRepository.isWorkTree else {
            fatalError(.illegal)
        }
        return worktreeRepository
    }

    private static func createWorktreeRepositoryIfNeeded(
        originalRepository: Repository,
        initialWorktreeBranchName: String,
        worktreeRepositoryURL: URL
    ) -> Repository {
        if let worktreeRepository = try? Repository.at(worktreeRepositoryURL).get() {
            return worktreeRepository
        } else {
            originalRepository
                .addWorkTree(
                    name: initialWorktreeBranchName,
                    path: worktreeRepositoryURL.path(percentEncoded: false)
                ).mustSucceed()
            return Repository.at(worktreeRepositoryURL).mustSucceed()
        }
    }

    @discardableResult
    static func checkoutOrCreateAndCheckoutBranchOfWorktreeIfNeeded(
        worktreeRepository: Repository,
        branchName: String,
        initialCommit: OID
    ) -> Branch {
        if let branch = try? worktreeRepository.branch(named: branchName).get() {
            worktreeRepository.checkout(branch.longName,.init(strategy: .Force)).mustSucceed()
            return branch
        } else {
            let branch = worktreeRepository.createBranch(
                branchName,
                oid: initialCommit,
                force: true
            ).mustSucceed()
            worktreeRepository.checkout(branch.longName,.init(strategy: .Force)).mustSucceed()
            return branch
        }
    }
}
