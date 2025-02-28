//
//  CommitsViewModel+RepositoryInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/23/25.
//

import Foundation

extension CommitsViewModel {
    func getRepositoryInfo(_ repository: Repository) async -> RepositoryInfo {
        let newRepositoryInfo: RepositoryInfo = RepositoryInfo(
            repository: repository
        ) { [weak self] type in
            guard let self else { return }
            Task {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    switch type {
                    case .head(let repositoryInfo):
                        repositoryInfo.detachedCommit = self.detachedCommit(of: repositoryInfo)
                        repositoryInfo.detachedTag = self.detachedTag(of: repositoryInfo)
                        repositoryInfo.historyCommits = self.historyCommits(of: repositoryInfo)
                        if let currentSelectedItem {
                            if case .regular(let item) = currentSelectedItem.selectedItemType {
                                if case .status(let selectableStatus) = item {
                                    if selectableStatus.repository.gitDir.path == repositoryInfo.repository.gitDir.path {
                                        let selectedItem = SelectedItem(selectedItemType: .regular(.status(SelectableStatus(repositoryInfo: repositoryInfo))))
                                        self.setCurrentSelectedItem(selectedItem)
                                    }
                                }
                            }
                        }
                    case .index(let repositoryInfo):
                        if let currentSelectedItem {
                            if case .regular(let item) = currentSelectedItem.selectedItemType {
                                if case .status(let selectableStatus) = item {
                                    if selectableStatus.repository.gitDir.path == repositoryInfo.repository.gitDir.path {
                                        let selectedItem = SelectedItem(selectedItemType: .regular(.status(SelectableStatus(repositoryInfo: repositoryInfo))))
                                        self.setCurrentSelectedItem(selectedItem)
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
        } onWorkDirChange: { [weak self] repositoryInfo, summary in
            guard let self else { return }
            guard autoCommitEnabled else { return }
            addWipCommit(repositoryInfo: repositoryInfo, summary: summary)
        }
        let (localBranches, remoteBranches, wipBranches) = branchInfos(of: newRepositoryInfo)
        newRepositoryInfo.localBranchInfos = localBranches
        newRepositoryInfo.remoteBranchInfos = remoteBranches
        newRepositoryInfo.wipBranchInfos = wipBranches
        newRepositoryInfo.tags = tags(of: newRepositoryInfo)
        newRepositoryInfo.stashes = stashes(of: newRepositoryInfo)
        newRepositoryInfo.detachedTag = detachedTag(of: newRepositoryInfo)
        newRepositoryInfo.detachedCommit = detachedCommit(of: newRepositoryInfo)
        newRepositoryInfo.historyCommits = historyCommits(of: newRepositoryInfo)
        newRepositoryInfo.status = StatusManager.shared.status(of: newRepositoryInfo.repository)
        return newRepositoryInfo
    }
    private func detachedAncestorCommitsOf(
        owner: SelectableDetachedCommit.Owner,
        in repositoryInfo: RepositoryInfo,
        count: Int = RepositoryInfo.commitCountLimit) -> [SelectableDetachedCommit]
    {
        var commits: [SelectableDetachedCommit] = []

        let commitIterator = CommitIterator(repo: repositoryInfo.repository, root: owner.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableDetachedCommit(repositoryInfo: repositoryInfo, commit: commit, owner: owner))
            counter += 1
        }
        return commits
    }
    private func stashes(of repositoryInfo: RepositoryInfo) -> [SelectableStash] {
        var stashes = [SelectableStash]()

        try? repositoryInfo.repository.stashes().get().forEach { stash in
            stashes.append(SelectableStash(repositoryInfo: repositoryInfo, stash: stash))
        }
        return stashes
    }

    private func branchInfos(of repositoryInfo: RepositoryInfo) ->
    (local: [RepositoryInfo.BranchInfo], remote: [RepositoryInfo.BranchInfo], wip: [RepositoryInfo.WipBranchInfo]) {
        let (localBranches, remoteBranches, wipBranches) = allBranches(of: repositoryInfo)
        let local = localBranches
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        let remote = remoteBranches
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        let wip = wipBranches
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.WipBranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = wipCommits(of: branch, in: repositoryInfo)
                return RepositoryInfo.WipBranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        return (local, remote, wip)
    }

    private func allBranches(of repositoryInfo: RepositoryInfo) -> (local: [Branch], remote: [Branch], wip: [Branch]) {
        var localBranches: [Branch] = []
        var remoteBranches: [Branch] = []
        var wipBranches: [Branch] = []
        let branchIterator = BranchIterator(repo: repositoryInfo.repository, type: .all)

        while let branch = try? branchIterator.next()?.get() {
            if branch.isWip {
                wipBranches.append(branch)
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
        return (localBranches, remoteBranches, wipBranches)
    }

    private func localBranchInfos(of repositoryInfo: RepositoryInfo) -> [RepositoryInfo.BranchInfo] {
        localBranches(of: repositoryInfo)
            .filter {
                !$0.isWip
            }
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
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

    private func remoteBranchInfos(of repositoryInfo: RepositoryInfo) -> [RepositoryInfo.BranchInfo] {
        repositoryInfo.repository.remoteBranches().mustSucceed()
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
    }

    private func detachedTag(of repositoryInfo: RepositoryInfo) -> RepositoryInfo.TagInfo? {
        switch repositoryInfo.head {
        case .branch:
            return nil
        case .tag(let tagReference, _):
            let detachedTag = SelectableDetachedTag(repositoryInfo: repositoryInfo, tag: tagReference)
            let commits = detachedAncestorCommitsOf(owner: SelectableDetachedCommit.Owner.tag(tagReference), in: repositoryInfo)
            return RepositoryInfo.TagInfo(tag: detachedTag, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
        case .reference(let reference, _):
            if let tag = try? repositoryInfo.repository.tag(reference.oid).get() {
                let tagReference = TagReference.annotated(tag.name, tag)
                let detachedTag = SelectableDetachedTag(repositoryInfo: repositoryInfo, tag: tagReference)
                let commits = detachedAncestorCommitsOf(owner: SelectableDetachedCommit.Owner.tag(tagReference), in: repositoryInfo)
                return RepositoryInfo.TagInfo(tag: detachedTag, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            } else {
                return nil
            }
        }
    }
    private func detachedCommit(of repositoryInfo: RepositoryInfo) -> RepositoryInfo.DetachedCommitInfo? {
        switch repositoryInfo.head {
        case .branch, .tag:
            return nil
        case .reference(let reference, _):
            if let commit = try? repositoryInfo.repository.commit(reference.oid).get() {
                let owner = SelectableDetachedCommit.Owner.commit(commit)
                let detachedCommit = SelectableDetachedCommit(repositoryInfo: repositoryInfo, commit: commit, owner: owner)
                let commits = detachedAncestorCommitsOf(owner: owner, in: repositoryInfo)
                return RepositoryInfo.DetachedCommitInfo(detachedCommit: detachedCommit, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            } else {
                return nil
            }
        }
    }
    private func tags(of repositoryInfo: RepositoryInfo) -> [RepositoryInfo.TagInfo] {
        var tags: [RepositoryInfo.TagInfo] = []

        try? repositoryInfo.repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
                let selectableTag = SelectableDetachedTag(repositoryInfo: repositoryInfo, tag: tag)
                let commits = detachedAncestorCommitsOf(owner: SelectableDetachedCommit.Owner.tag(tag), in: repositoryInfo)
                tags.append(RepositoryInfo.TagInfo(tag: selectableTag, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head))
            }
        return tags
    }
    private func commits(
        of branch: Branch,
        in repositoryInfo: RepositoryInfo,
        count: Int = RepositoryInfo.commitCountLimit) -> [SelectableCommit] {
            var commits: [SelectableCommit] = []

            let commitIterator = CommitIterator(repo: repositoryInfo.repository, root: branch.oid.oid)
            var counter = 0
            while counter < count, let commit = try? commitIterator.next()?.get() {
                commits.append(SelectableCommit(repositoryInfo: repositoryInfo, branch: branch, commit: commit))
                counter += 1
            }
            return commits
        }
    private func wipCommits(
        of branch: Branch,
        in repositoryInfo: RepositoryInfo,
        count: Int = RepositoryInfo.commitCountLimit) -> [SelectableWipCommit] {
            var commits: [SelectableWipCommit] = []

            let commitIterator = CommitIterator(repo: repositoryInfo.repository, root: branch.oid.oid)
            var counter = 0
            while counter < count, let commit = try? commitIterator.next()?.get() {
                commits.append(SelectableWipCommit(repositoryInfo: repositoryInfo, branch: branch, commit: commit))
                counter += 1
            }
            return commits
        }

#warning("history not implemented")
    private func historyCommits(of repositoryInfo: RepositoryInfo) -> [SelectableHistoryCommit] {
        []
    }
}
