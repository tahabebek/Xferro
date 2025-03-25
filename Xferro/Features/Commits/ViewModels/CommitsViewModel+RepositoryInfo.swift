//
//  CommitsViewModel+RepositoryInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/23/25.
//

import Foundation

extension CommitsViewModel {
    func getRepositoryInfo(_ repository: Repository) async -> RepositoryInfo {
        let newRepositoryInfo: RepositoryInfo = RepositoryInfo(repository: repository)

        newRepositoryInfo.onGitChange = { [weak self, weak newRepositoryInfo] type in
            guard let self, let newRepositoryInfo else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                switch type {
                case .head(let repositoryInfo):
                    repositoryInfo.detachedCommit = self.detachedCommit(of: repositoryInfo)
                    repositoryInfo.detachedTag = self.detachedTag(of: repositoryInfo)
                    repositoryInfo.historyCommits = self.historyCommits(of: repositoryInfo)
                    if let currentSelectedItem {
                        if case .regular(let item) = currentSelectedItem.type {
                            if case .status = item {
                                if newRepositoryInfo.repository.gitDir.path == repositoryInfo.repository.gitDir.path {
                                    let selectedItem = SelectedItem(type: .regular(.status(
                                        SelectableStatus(repositoryInfo: repositoryInfo))))
                                    self.setCurrentSelectedItem(selectedItem, repositoryInfo)
                                }
                            }
                        }
                    }
                case .index(let repositoryInfo):
                    if let currentSelectedItem {
                        if case .regular(let item) = currentSelectedItem.type {
                            if case .status = item {
                                if repositoryInfo.repository.gitDir.path == newRepositoryInfo.repository.gitDir.path {
                                    let selectedItem = SelectedItem(type: .regular(.status(SelectableStatus(
                                        repositoryInfo: repositoryInfo
                                    ))))
                                    self.setCurrentSelectedItem(selectedItem, repositoryInfo)
                                }
                            }
                        }
                    }
                case .localBranches(let repositoryInfo):
                    repositoryInfo.localBranchInfos = self.localBranchInfos(of: repositoryInfo)
                case .remoteBranches(let repositoryInfo):
                    repositoryInfo.remoteBranchInfos = self.remoteBranchInfos(of: repositoryInfo)
                case .tags(let repositoryInfo):
                    repositoryInfo.tags = self.tags(of: repositoryInfo)
                case .reflog:
#warning("reflog not implemented")
                    break
                case .stash(let repositoryInfo):
                    repositoryInfo.stashes = self.stashes(of: repositoryInfo)
                }
            }
        }
        newRepositoryInfo.onWorkDirChange = { [weak self] repositoryInfo, summary in
            guard let self else { return }
            guard UserDefaults.standard.autoCommitEnabled else { return }
            addWipCommit(repositoryInfo: repositoryInfo, summary: summary)
        }
        newRepositoryInfo.onUserTapped = { [weak self, weak newRepositoryInfo] in
            guard let self, let newRepositoryInfo else { return }
            userTapped(item: $0, repositoryInfo: newRepositoryInfo)
        }
        newRepositoryInfo.onIsSelected = { [weak self] in
            guard let self else { return false }
            return isSelected(item: $0)
        }
        newRepositoryInfo.onDeleteRepositoryTapped = { [weak self] in
            guard let self else { return }
            deleteRepositoryTapped($0)
        }
        newRepositoryInfo.onDeleteBranchTapped = { [weak self] in
            guard let self else { return }
            deleteBranchTapped(repository: repository, branchName: $0)
        }
        newRepositoryInfo.onIsCurrentBranch = { [weak self] in
            guard let self else { return false }
            return isCurrentBranch($0, head: $1)
        }
        let (localBranches, remoteBranches) = branchInfos(of: newRepositoryInfo)
        newRepositoryInfo.localBranchInfos = localBranches
        newRepositoryInfo.remoteBranchInfos = remoteBranches
        newRepositoryInfo.tags = tags(of: newRepositoryInfo)
        newRepositoryInfo.stashes = stashes(of: newRepositoryInfo)
        newRepositoryInfo.detachedTag = detachedTag(of: newRepositoryInfo)
        newRepositoryInfo.detachedCommit = detachedCommit(of: newRepositoryInfo)
        newRepositoryInfo.historyCommits = historyCommits(of: newRepositoryInfo)
        newRepositoryInfo.remotes = repository.allRemotes().mustSucceed(repository.gitDir)
        Task {
            newRepositoryInfo.status = await StatusManager.shared.status(of: newRepositoryInfo.repository)
        }
        return newRepositoryInfo
    }
    private func stashes(of repositoryInfo: RepositoryInfo) -> [SelectableStash] {
        var stashes = [SelectableStash]()

        try? repositoryInfo.repository.stashes().get().forEach { stash in
            stashes.append(SelectableStash(repositoryInfo: repositoryInfo, stash: stash))
        }
        return stashes
    }

    private func branchInfos(of repositoryInfo: RepositoryInfo) ->
    (local: [BranchInfo], remote: [BranchInfo]) {
        let (localBranches, remoteBranches) = allBranches(of: repositoryInfo)
        let local = localBranches
            .map {
                BranchInfo(branch: $0, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        let remote = remoteBranches
            .map {
                BranchInfo(branch: $0, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        return (local, remote)
    }

    private func allBranches(of repositoryInfo: RepositoryInfo) -> (local: [Branch], remote: [Branch]) {
        var localBranches: [Branch] = []
        var remoteBranches: [Branch] = []
        let branchIterator = BranchIterator(repo: repositoryInfo.repository, type: .all)

        while let branch = try? branchIterator.next()?.get() {
            if branch.isWip {
                continue
            } else if branch.isLocal {
                if isCurrentBranch(branch, head: repositoryInfo.head) {
                    localBranches.insert(branch, at: 0)
                } else {
                    localBranches.append(branch)
                }
            } else if branch.isRemote {
                remoteBranches.append(branch)
            } else {
                fatalError(.illegal)
            }
        }
        return (localBranches, remoteBranches)
    }

    private func localBranchInfos(of repositoryInfo: RepositoryInfo) -> [BranchInfo] {
        localBranches(of: repositoryInfo)
            .filter {
                !$0.isWip
            }
            .map {
                BranchInfo(branch: $0, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
    }

    private func localBranches(of repositoryInfo: RepositoryInfo) -> [Branch] {
        var branches: [Branch] = []
        let branchIterator = BranchIterator(repo: repositoryInfo.repository, type: .local)

        while let branch = try? branchIterator.next()?.get() {
            if isCurrentBranch(branch, head: repositoryInfo.head) {
                branches.insert(branch, at: 0)
            } else {
                branches.append(branch)
            }
        }
        return branches
    }

    private func remoteBranchInfos(of repositoryInfo: RepositoryInfo) -> [BranchInfo] {
        repositoryInfo.repository.remoteBranches().mustSucceed(repositoryInfo.repository.gitDir)
            .map {
                BranchInfo(
                    branch: $0,
                    repository: repositoryInfo.repository,
                    head: repositoryInfo.head
                )
            }
    }

    private func detachedTag(of repositoryInfo: RepositoryInfo) -> TagInfo? {
        switch repositoryInfo.head {
        case .branch:
            return nil
        case .tag(let tagReference, _):
            let detachedTag = SelectableDetachedTag(
                repositoryInfo: repositoryInfo,
                tag: tagReference
            )
            return TagInfo(tag: detachedTag, repository: repositoryInfo.repository, head: repositoryInfo.head)
        case .reference(let reference, _):
            if let tag = try? repositoryInfo.repository.tag(reference.oid).get() {
                let tagReference = TagReference.annotated(tag.name, tag)
                let detachedTag = SelectableDetachedTag(
                    repositoryInfo: repositoryInfo,
                    tag: tagReference
                )
                return TagInfo(
                    tag: detachedTag,
                    repository: repositoryInfo.repository,
                    head: repositoryInfo.head
                )
            } else {
                return nil
            }
        }
    }
    private func detachedCommit(of repositoryInfo: RepositoryInfo) -> DetachedCommitInfo? {
        switch repositoryInfo.head {
        case .branch, .tag:
            return nil
        case .reference(let reference, _):
            if let commit = try? repositoryInfo.repository.commit(reference.oid).get() {
                let owner = SelectableDetachedCommit.Owner.commit(commit)
                let detachedCommit = SelectableDetachedCommit(
                    repositoryInfo: repositoryInfo,
                    commit: commit,
                    owner: owner
                )
                return DetachedCommitInfo(detachedCommit: detachedCommit, owner: owner, repository: repositoryInfo.repository, head: repositoryInfo.head)
            } else {
                return nil
            }
        }
    }
    private func tags(of repositoryInfo: RepositoryInfo) -> [TagInfo] {
        var tags: [TagInfo] = []

        try? repositoryInfo.repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
                let selectableTag = SelectableDetachedTag(
                    repositoryInfo: repositoryInfo,
                    tag: tag
                )
                tags.append(TagInfo(
                    tag: selectableTag,
                    repository: repositoryInfo.repository,
                    head: repositoryInfo.head
                ))
            }
        return tags
    }

#warning("history not implemented")
    private func historyCommits(of repositoryInfo: RepositoryInfo) -> [SelectableHistoryCommit] {
        return []
    }
}
