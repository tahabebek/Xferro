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
    var autoCommitEnabled: Bool

    init(
        commits: [SelectableWipCommit],
        item: SelectedItem,
        repositoryInfo: RepositoryInfo,
        autoCommitEnabled: Bool
    ) {
        self.commits = commits
        self.item = item
        self.repositoryInfo = repositoryInfo
        self.autoCommitEnabled = autoCommitEnabled
    }

    var isNotEmpty: Bool { commits.isNotEmpty }
}
