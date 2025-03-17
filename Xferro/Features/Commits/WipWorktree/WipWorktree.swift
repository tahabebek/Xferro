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
    static let wipCommitMessage = "Xferro wip commit"
    let worktreeRepository: Repository
    let originalRepository: Repository
    let name: String

    static func worktreeName(for originalRepository: Repository) -> String {
        Self.worktreeRepositoryURL(originalRepository: originalRepository).path.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "/", with: "_")
    }

    static func get(for originalRepository: Repository) -> WipWorktree? {
        let name = worktreeName(for: originalRepository)
        guard let worktreeRepository = try? originalRepository.worktree(named: name).get()
        else { return nil }
        return WipWorktree(
            worktreeRepository: worktreeRepository,
            originalRepository: originalRepository,
            name: name
        )
    }

    static func worktree(for repositoryInfo: RepositoryInfo) -> WipWorktree {
        let repository = repositoryInfo.repository
        let headOID = repositoryInfo.headOID
        let worktreeRepositoryURL =  worktreeRepositoryURL(originalRepository: repository)
        let worktreeName = worktreeName(for: repository)

        if let existingWorktree = get(for: repository) {
            return existingWorktree
        } else {
            let branchName = worktreeBranchName(item: SelectableStatus(repositoryInfo: repositoryInfo))
            let newBranch: Branch?
            do {
                newBranch = try repository.createBranch(branchName, oid: headOID).get()
            } catch {
                if GIT_EEXISTS.rawValue == error.code {
                    // this probably means the worktree folder is deleted by the user (or system) from the caches directory
                    deleteWipWorktree(for: repository)
                    newBranch = repository.createBranch(branchName, oid: headOID).mustSucceed(repository.gitDir)
                } else {
                    fatalError(.unhandledRepositoryError(repository.gitDir))
                }
            }
            guard let newBranch else {
                fatalError(.impossible)
            }
            repository
                .addWorkTree(
                    name: worktreeName,
                    path: worktreeRepositoryURL.path
                ).mustSucceed(repository.gitDir)
            let worktreeRepository = try! Repository.at(worktreeRepositoryURL).get()
            Head.checkout(repository: worktreeRepository, longName: newBranch.longName).mustSucceed(worktreeRepository.gitDir)
            return WipWorktree(
                worktreeRepository: worktreeRepository,
                originalRepository: repository,
                name: worktreeName
            )
        }
    }

    private init(
        worktreeRepository: Repository,
        originalRepository: Repository,
        name: String
    ) {
        self.worktreeRepository = worktreeRepository
        self.originalRepository = originalRepository
        self.name = name
    }

    static func worktreeRepositoryURL(originalRepository: Repository)  -> URL {
        let originalRepositoryPath =  originalRepository.gitDir.deletingLastPathComponent().path()

        let worktreeRepositoryURL = DataManager.appDir.appendingPathComponent(Self.wipWorktreeFolder)
            .appendingPathComponent(String(originalRepositoryPath.dropFirst()))
            .appendingPathComponent("WipWorktree")
        try? FileManager.createDirectory(
            worktreeRepositoryURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        return worktreeRepositoryURL
    }

    static func worktreeBranchName(item: any SelectableItem) -> String {
        switch item {
        case let status as SelectableStatus:
            switch status.type {
            case .branch(_, let branch):
                "\(Self.wipBranchesPrefix)for_branch_\(branch.wipName)"
            case .tag(_, let tag):
                "\(Self.wipBranchesPrefix)for_tag_\(tag.wipName)"
            case .detached(_, let commit):
                "\(Self.wipBranchesPrefix)for_detached_commit_\(commit.oid.description)"
            }
        case let commit as SelectableCommit:
            "\(Self.wipBranchesPrefix)for_branch_\(commit.branch.wipName)"
        case let detachedCommit as SelectableDetachedCommit:
            "\(Self.wipBranchesPrefix)for_detached_commit_\(detachedCommit.oid.description)"
        case let detachedTag as SelectableDetachedTag:
            "\(Self.wipBranchesPrefix)for_detached_tag_\(detachedTag.tag.wipName)"
        case let tag as SelectableTag:
            "\(Self.wipBranchesPrefix)for_tag_\(tag.tag.wipName)"
        default:
            fatalError(.unimplemented)
        }
    }

    static func worktreeBranchName(for item: SelectedItem) -> String {
        worktreeBranchName(item: item.selectableItem)
    }

    static func deleteWipWorktree(for repository: Repository) {
        let worktreeName = WipWorktree.worktreeName(for: repository)
        let worktreePath = Self.worktreeRepositoryURL(originalRepository: repository).path
        repository.pruneWorkTree(worktreeName, force: true).mustSucceed(repository.gitDir)
        if FileManager.fileExists(worktreePath) {
            try! FileManager.removeItem(URL(filePath: worktreePath, directoryHint: .isDirectory))
        }

        let branchIterator = BranchIterator(repo: repository, type: .local)
        while let branch = try? branchIterator.next()?.get() {
            if branch.name.hasPrefix(WipWorktree.wipBranchesPrefix) {
                repository.deleteBranch(branch.name).mustSucceed(repository.gitDir)
            }
        }
    }
    
    static func deleteAllWipCommits(item: SelectedItem, repository: Repository) {
        let worktreeRepository = WipWorktree.worktreeRepository(of: repository)
        let worktreeName = WipWorktree.worktreeName(for: repository)
        let currentBranchNameOfWorktreeRepository = WipWorktree.currentBranchName(ofWorktreeRepository: worktreeRepository, name: worktreeName)
        let branchNameOfItemInWorktreeRepository = WipWorktree.worktreeBranchName(item: item.selectableItem)

        var shouldDeleteBranch = true
        switch item.type {
        case .regular(let type):
            switch type {
            case .commit:
                if currentBranchNameOfWorktreeRepository == branchNameOfItemInWorktreeRepository {
                    shouldDeleteBranch = false
                }
            case .historyCommit, .detachedCommit, .detachedTag, .tag, .status:
                shouldDeleteBranch = false
            case .stash:
                fatalError(.invalid)
            }
        case .wip:
            fatalError(.invalid)
        }

        if shouldDeleteBranch {
            repository.deleteBranch(branchNameOfItemInWorktreeRepository).mustSucceed(repository.gitDir)
        } else {
            worktreeRepository.reset(oid: item.selectableItem.oid , type: .hard).mustSucceed(worktreeRepository.gitDir)
        }
    }

    static func worktreeRepository(of repository: Repository) -> Repository {
        let worktreeRepositoryURL = WipWorktree.worktreeRepositoryURL(originalRepository: repository)
        guard try! Repository.isGitRepository(url: worktreeRepositoryURL).get() else {
            fatalError(.impossible)
        }
        let worktreeRepository = try! Repository.at(worktreeRepositoryURL).get()
        guard worktreeRepository.isWorkTree else {
            fatalError(.illegal)
        }
        return worktreeRepository
    }

    static func currentBranchName(ofWorktreeRepository repository: Repository, name: String) -> String {
        let head = Head.of(worktree: name, in: repository)
        var currentBranchName: String

        switch head {
        case .branch(let branch, _):
            currentBranchName = branch.name
        case .tag:
            fatalError("Head should never be a tag for a worktree")
        case .reference:
            fatalError("Head should never be detached for a worktree.")
        }
        return currentBranchName
    }

    func getBranch(branchName: String) -> Branch? {
        worktreeRepository.localBranch(named: branchName).mustSucceed(worktreeRepository.gitDir)
    }

    @discardableResult
    func createBranch(branchName: String, oid: OID) -> Branch {
        worktreeRepository.createBranch(
            branchName,
            oid: oid,
            force: true
        ).mustSucceed(worktreeRepository.gitDir)
    }

    func checkout(branchName: String) {
        Head.checkout(repository: worktreeRepository, longName: branchName.longBranchRef,.init(strategy: .Force))
            .mustSucceed(worktreeRepository.gitDir)
    }

    @discardableResult
    func merge(with oid: OID, message: String) -> Result<GitMergeAnalysisStatus, NSError> {
        worktreeRepository.merge(with: oid, message: message, conflictStrategy: MergeConflictStrategy.acceptTheirs)
    }

    func addToWorktreeIndex(path: String) {
        worktreeRepository.stage(path: path).mustSucceed(worktreeRepository.gitDir)
    }

    @discardableResult
    func commit(summary: String? = nil) -> Commit {
        worktreeRepository.commit(message: summary ?? Self.wipCommitMessage).mustSucceed(worktreeRepository.gitDir)
    }

    func wipCommits(
        repositoryInfo: RepositoryInfo,
        branchName: String,
        owner: any SelectableItem
    ) -> [SelectableWipCommit] {
        guard let branch =  getBranch(branchName: branchName) else {
            fatalError("branch \(branchName) not found")
        }

        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: worktreeRepository, root: branch.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits
                .append(
                    SelectableWipCommit(
                        repositoryInfo: repositoryInfo,
                        owner: owner,
                        branch: branch,
                        commit: commit
                    )
                )
        }
        return commits
    }
}
