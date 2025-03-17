//
//  TagInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//


import Foundation

class TagInfo: Identifiable {
    var id: String {
        "\(tag.id)"
    }

    init(tag: SelectableDetachedTag, repository: Repository, head: Head, _commits: [SelectableDetachedCommit]? = nil) {
        self.tag = tag
        self.repository = repository
        self.head = head
        self._commits = _commits
    }

    let tag: SelectableDetachedTag
    let repository: Repository
    let head: Head
    var _commits: [SelectableDetachedCommit]?

    func commits() async -> [SelectableDetachedCommit] {
        if let _commits {
            return _commits
        }
        let commits = await detachedAncestorCommitsOf(owner: SelectableDetachedCommit.Owner.tag(tag.tag))
        _commits = commits
        return commits
    }


    private func detachedAncestorCommitsOf(
        owner: SelectableDetachedCommit.Owner,
        count: Int = RepositoryInfo.commitCountLimit) async -> [SelectableDetachedCommit]
    {
        var commits: [SelectableDetachedCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: owner.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableDetachedCommit(
                repositoryId: repository.idOfRepo,
                repositoryName: repository.nameOfRepo,
                repositoryGitDir: repository.gitDir.path,
                commit: commit,
                owner: owner
            ))
            counter += 1
        }
        return commits
    }
}
