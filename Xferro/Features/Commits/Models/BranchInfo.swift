//
//  BranchInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation

class BranchInfo: Identifiable, Equatable {
    var id: String {
        "\(branch.name).\(branch.commit.oid.description)"
    }
    static func == (lhs: BranchInfo, rhs: BranchInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    let branch: Branch
    let repository: Repository
    let head: Head
    private var _commits: [SelectableCommit]?

    func commits(count: Int = RepositoryViewModel.commitCountLimit) async -> [SelectableCommit] {
        if let _commits {
            return _commits
        }

        print("get commits")
        var commits: [SelectableCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: branch.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableCommit(
                repositoryGitDir: repository.gitDir.path,
                repositoryName: repository.nameOfRepo,
                repositoryId: repository.idOfRepo,
                branch: branch,
                commit: commit
            ))
            counter += 1
        }
        _commits = commits
        return commits
    }

    init(branch: Branch, repository: Repository, head: Head, _commits: [SelectableCommit]? = nil) {
        self.branch = branch
        self.repository = repository
        self.head = head
        self._commits = _commits
    }
}
