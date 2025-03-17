//
//  DetachedCommitInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//


import Foundation

class DetachedCommitInfo: Identifiable {
    var id: String {
        detachedCommit.id
    }

    static func == (lhs: DetachedCommitInfo, rhs: DetachedCommitInfo) -> Bool {
        lhs.id == rhs.id
    }

    init(detachedCommit: SelectableDetachedCommit!, owner: SelectableDetachedCommit.Owner, repository: Repository, head: Head, _commits: [SelectableDetachedCommit]? = nil) {
        self.detachedCommit = detachedCommit
        self.owner = owner
        self.repository = repository
        self.head = head
        self._commits = _commits
    }
    
    var detachedCommit: SelectableDetachedCommit!
    let owner: SelectableDetachedCommit.Owner
    let repository: Repository
    let head: Head
    var _commits: [SelectableDetachedCommit]?

    func commits() async -> [SelectableDetachedCommit] {
        if let _commits {
            return _commits
        }
        let commits = await detachedAncestorCommitsOf(owner: owner)
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
