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
    static let wipCommitMessage = "Wip commit"
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

    static func worktree(for repository: Repository, headOID: OID) -> WipWorktree {
        let worktreeRepositoryURL =  worktreeRepositoryURL(originalRepository: repository)
        let worktreeName = worktreeName(for: repository)

        if let existingWorktree = get(for: repository) {
            return existingWorktree
        } else {
            let branchName = worktreeBranchName(item: nil)
            let newBranch: Branch?
            do {
                newBranch = try repository.createBranch(branchName, oid: headOID).get()
            } catch {
                if GIT_EEXISTS.rawValue == error.code {
                    // this probably means the worktree folder is deleted by the user (or system) from the caches directory
                    deleteWipWorktree(for: repository)
                    newBranch = repository.createBranch(branchName, oid: headOID).mustSucceed()
                } else {
                    fatalError(.unhandledError)
                }
            }
            guard let newBranch else {
                fatalError(.impossible)
            }
            repository
                .addWorkTree(
                    name: worktreeName,
                    path: worktreeRepositoryURL.path
                ).mustSucceed()
            let worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
            Head.checkout(repository: worktreeRepository, longName: newBranch.longName).mustSucceed()
            return WipWorktree(worktreeRepository: worktreeRepository, originalRepository: repository)
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

    static func worktreeBranchName(item: (any SelectableItem)?) -> String {
        guard let item else {
            return Self.wipBranchesPrefix
        }
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

    static func worktreeBranchName(for item: SelectedItem?) -> String {
        worktreeBranchName(item: item?.selectableItem)
    }

    static func deleteWipWorktree(for repository: Repository) {
        let worktreeName = WipWorktree.worktreeName(for: repository)
        let worktreePath = Self.worktreeRepositoryURL(originalRepository: repository).path
        repository.pruneWorkTree(worktreeName, force: true).mustSucceed()
        if FileManager.default.fileExists(atPath: worktreePath) {
            try! FileManager.default.removeItem(at: URL(filePath: worktreePath, directoryHint: .isDirectory))
        }

        let branchIterator = BranchIterator(repo: repository, type: .local)
        while let branch = try? branchIterator.next()?.get() {
            if branch.name.hasPrefix(WipWorktree.wipBranchesPrefix) {
                repository.deleteBranch(branch.name).mustSucceed()
            }
        }
    }
    
    static func deleteAllWipCommits(of item: SelectedItem) {
        let worktreeRepository = WipWorktree.worktreeRepository(of: item.repository)
        let worktreeName = WipWorktree.worktreeName(for: item.repository)
        let currentBranchNameOfWorktreeRepository = WipWorktree.currentBranchName(ofWorktreeRepository: worktreeRepository, name: worktreeName)
        let branchNameOfItemInWorktreeRepository = WipWorktree.worktreeBranchName(item: item.selectableItem)

        var shouldDeleteBranch = true
        switch item.selectedItemType {
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
            item.repository.deleteBranch(branchNameOfItemInWorktreeRepository).mustSucceed()
        } else {
            worktreeRepository.reset(oid: item.selectableItem.oid , type: .hard).mustSucceed()
        }
    }

    static func worktreeRepository(of repository: Repository) -> Repository {
        let worktreeRepositoryURL = WipWorktree.worktreeRepositoryURL(originalRepository: repository)
        guard Repository.isGitRepository(url: worktreeRepositoryURL).mustSucceed() else {
            fatalError(.impossible)
        }
        let worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
        guard worktreeRepository.isWorkTree else {
            fatalError(.illegal)
        }
        return worktreeRepository
    }

    static func currentBranchName(ofWorktreeRepository repository: Repository, name: String) -> String {
        let head = Head.of(worktree: name, in: repository)
        var currentBranchName: String

        switch head {
        case .branch(let branch):
            currentBranchName = branch.name
        case .tag:
            fatalError("Head should never be a tag for a worktree")
        case .reference:
            fatalError("Head should never be detached for a worktree.")
        }
        return currentBranchName
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
        Head.checkout(repository: worktreeRepository, longName: branchName.longBranchRef,.init(strategy: .Force)).mustSucceed()
    }

    func addToWorktreeIndex(path: String) {
        worktreeRepository.stage(path: path).mustSucceed()
    }

    @discardableResult
    func commit(summary: String? = nil) -> Commit {
        worktreeRepository.commit(message: summary ?? Self.wipCommitMessage).mustSucceed()
    }

    func wipCommits(repositoryInfo: RepositoryInfo, branchName: String, stop: OID) -> [SelectableWipCommit] {
        guard let branch =  getBranch(branchName: branchName) else {
            fatalError("branch \(branchName) not found")
        }

        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: worktreeRepository, root: branch.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableWipCommit(repositoryInfo: repositoryInfo, branch: branch, commit: commit))
            if commit.oid == stop {
                break
            }
        }
        return commits
    }
}
