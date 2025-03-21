//
//  WipCommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import Observation

@Observable final class WipCommitsViewModel {
    var commits: [SelectableWipCommit]
    var item: SelectedItem
    let repositoryInfo: RepositoryInfo
    let branchName: String

    init(
        commits: [SelectableWipCommit],
        item: SelectedItem,
        repositoryInfo: RepositoryInfo,
        branchName: String
    ) {
        self.commits = commits
        self.item = item
        self.repositoryInfo = repositoryInfo
        self.branchName = branchName
    }

    var isNotEmpty: Bool { commits.isNotEmpty }
}
