//
//  RepoInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Foundation

struct RepositoryInfo: Identifiable {
    struct BranchInfo: Identifiable {
        var id: String {
            branch.name + branch.commit.oid.description
        }
        let branch: Branch
        let commits: [SelectableCommit]
    }
    var id: String {
        let repoId = repository.gitDir.path
        let branchInfosId = branchInfos.reduce(into: "") { result, info in
            result += info.id
        }
        let tagsId = tags.reduce(into: "") { result, tag in
            result += tag.id
        }
        let stashesId = stashes.reduce(into: "") { result, stash in
            result += stash.id
        }
        let detachedCommitId = detachedCommit?.id ?? ""
        let detachedTagId = detachedTag?.id ?? ""
        let historyCommitsId = historyCommits.reduce(into: "") { result, commit in
            result += commit.id
        }
        return repoId + branchInfosId + tagsId + stashesId + detachedCommitId + detachedTagId + historyCommitsId
    }

    let repository: Repository
    let branchInfos: [BranchInfo]
    let tags: [SelectableTag]
    let stashes: [SelectableStash]
    let detachedTag: SelectableDetachedTag?
    let detachedCommit: SelectableDetachedCommit?
    let historyCommits: [SelectableHistoryCommit]
}

extension CommitsViewModel {
    func getRepositoryInfo(_ repository: Repository) -> RepositoryInfo {
        let branches = branches(of: repository)
        let branchInfos: [RepositoryInfo.BranchInfo] = branches.map { [weak self] branch in
            guard let self else { return .init(branch: branch, commits: []) }
            let commits = commits(of: branch, in: repository)
            return RepositoryInfo.BranchInfo(branch: branch, commits: commits)
        }

        let newRepositoryInfo: RepositoryInfo = RepositoryInfo(
            repository: repository,
            branchInfos: branchInfos,
            tags: tags(of: repository),
            stashes: stashes(of: repository),
            detachedTag: detachedTag(of: repository),
            detachedCommit: detachedCommit(of: repository),
            historyCommits: historyCommits(of: repository)
        )
        return newRepositoryInfo
    }

    func detachedAncestorCommitsOf(oid: OID, in repository: Repository, count: Int = 25) -> [SelectableDetachedCommit] {
        var commits: [SelectableDetachedCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableDetachedCommit(repository: repository, commit: commit))
            counter += 1
        }
        return commits
    }

    func detachedCommits(of tag: SelectableDetachedTag, in repository: Repository, count: Int = 25) -> [SelectableDetachedCommit] {
        detachedAncestorCommitsOf(oid: tag.tag.oid, in: repository, count: count)
    }

    private func stashes(of repository: Repository) -> [SelectableStash] {
        var stashes = [SelectableStash]()

        try? repository.stashes().get().forEach { stash in
            stashes.append(SelectableStash(repository: repository, stash: stash))
        }
        return stashes
    }
    private func branches(of repository: Repository) -> [Branch] {
        var branches: [Branch] = []
        let head = Head.of(repository)

        let branchIterator = BranchIterator(repo: repository, type: .local)

        while let branch = try? branchIterator.next()?.get() {
            if branch.name.hasPrefix(WipWorktree.wipBranchesPrefix) { continue }
            if isCurrentBranch(branch, head: head, in: repository) {
                branches.insert(branch, at: 0)
            } else {
                branches.append(branch)
            }
        }
        return branches
    }
    private func detachedTag(of repository: Repository) -> SelectableDetachedTag? {
        let head = Head.of(repository)
        switch head {
        case .branch:
            return nil
        case .tag(let tagReference):
            return SelectableDetachedTag(repository: repository, tag: tagReference)
        case .reference(let reference):
            if let tag = try? repository.tag(reference.oid).get() {
                return SelectableDetachedTag(repository: repository, tag: TagReference.annotated(tag.name, tag))
            }
        }
        return nil
    }
    private func detachedCommit(of repository: Repository) -> SelectableDetachedCommit? {
        let head = Head.of(repository)
        switch head {
        case .branch, .tag:
            return nil
        case .reference(let reference):
            if let commit = try? repository.commit(reference.oid).get() {
                return SelectableDetachedCommit(repository: repository, commit: commit)
            }
        }
        return nil
    }
    private func tags(of repository: Repository) -> [SelectableTag] {
        var tags: [SelectableTag] = []

        try? repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
                tags.append(SelectableTag(repository: repository, tag: tag))
            }
        return tags
    }
    private func commits(of branch: Branch, in repository: Repository, count: Int = 10) -> [SelectableCommit] {
        var commits: [SelectableCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: branch.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableCommit(repository: repository, branch: branch, commit: commit))
            counter += 1
        }
        return commits
    }
    private func historyCommits(of repository: Repository) -> [SelectableHistoryCommit] {
        []
    }
}
