//
//  CommitsViewModel+Wip.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

extension CommitsViewModel {
    func getWipCommits(selectedItem: SelectedItem?) {
        guard let selectedItem else {
            Task {
                await MainActor.run {
                    currentWipCommits = nil
                }
            }
            return
        }

        var branchName: String?
        switch selectedItem.selectedItemType {
        case .regular(let type):
            switch type {
            case .status, .commit, .detachedCommit, .detachedTag:
                branchName = WipWorktree.worktreeBranchName(for: selectedItem)
            default:
                break
            }
        case .wip:
            break
        }

        guard let branchName else { return }
        if selectedItem.wipWorktree.getBranch(branchName: branchName) == nil {
            selectedItem.wipWorktree.createBranch(branchName: branchName, oid: selectedItem.oid)
        }
        let wipCommits =  selectedItem.wipWorktree.wipCommits(
            repositoryInfo: selectedItem.repositoryInfo,
            branchName: branchName
        )
        Task {
            await MainActor.run {
                currentWipCommits = CurrentWipCommits(commits: wipCommits, item: selectedItem)
            }
        }
    }

    func deleteWipWorktreeTapped(for repository: Repository) {
        deleteWipWorktree(for: repository)
    }

    private func deleteWipWorktree(for repository: Repository) {
        WipWorktree.deleteWipWorktree(for: repository)
        currentWipCommits = nil
    }

    func deleteAllWipCommitsTapped(for item: SelectedItem) {
        deleteAllWipCommits(of: item)
    }

    private func deleteAllWipCommits(of item: SelectedItem) {
        WipWorktree.deleteAllWipCommits(of: item)
        Task {
            await MainActor.run {
                currentWipCommits = nil
            }
        }
    }

    func addManualWipCommitTapped(for item: SelectedItem) {
        addManualWipCommit(for: item)
    }
    private func addManualWipCommit(for item: SelectedItem) {
        addWipCommit(repositoryInfo: item.repositoryInfo)
    }

    func addWipCommit(repositoryInfo: RepositoryInfo, summary: String? = nil) {
        wipCommitLock.lock()
        defer { wipCommitLock.unlock() }
        let worktree = repositoryInfo.wipWorktree
        let selectableItem = SelectableStatus(repositoryInfo: repositoryInfo)
        let branchName = WipWorktree.worktreeBranchName(item: selectableItem)
        if worktree.getBranch(branchName: branchName) == nil {
            worktree.createBranch(branchName: branchName, oid: selectableItem.oid)
        }

        let worktreeHead = Head.of(worktree: worktree.name, in: repositoryInfo.repository)
        if worktreeHead.name != branchName {
            worktree.checkout(branchName: branchName)
        }
        worktree.addToWorktreeIndex(path: ".")
        worktree.commit(summary: summary)
        let originalRepoHead = repositoryInfo.head
        if worktreeHead.time < originalRepoHead.time {
            _ = try? worktree.merge(with: originalRepoHead.oid, message: "Merge from branch").get()
        }

        self.reloadUIAfterAddingWipCommits(repositoryInfo: repositoryInfo)
    }
    func reloadUIAfterAddingWipCommits(repositoryInfo: RepositoryInfo) {
        let repository = repositoryInfo.repository
        let head = repositoryInfo.head
        if let currentSelectedItem, repository.gitDir.path == currentSelectedItem.repository.gitDir.path {
            var isHead = false
            let headId = head.oid
            switch currentSelectedItem.selectedItemType {
            case .regular(let type):
                switch type {
                case .status:
                    isHead = true
                case .commit(let selectableCommit):
                    if selectableCommit.oid == headId {
                        isHead = true
                    }
                case .historyCommit(let selectableHistoryCommit):
                    if selectableHistoryCommit.oid == headId {
                        isHead = true
                    }
                case .detachedCommit(let selectableDetachedCommit):
                    if selectableDetachedCommit.oid == headId {
                        isHead = true
                    }
                case .detachedTag(let selectableDetachedTag):
                    if selectableDetachedTag.oid == headId {
                        isHead = true
                    }
                case .tag(let selectableTag):
                    if selectableTag.oid == headId {
                        isHead = true
                    }
                case .stash:
                    break
                }
            case .wip:
                break
            }

            if isHead {
                Task {
                    await MainActor.run {
                        updateDetailInfoAndPeekInfo()
                        getWipCommits(selectedItem: currentSelectedItem)
                    }
                }
            }
        }

    }
}
