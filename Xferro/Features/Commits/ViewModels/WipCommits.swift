//
//  WipCommits.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import Observation

@Observable final class WipCommits {
    var commits: [SelectableWipCommit]
    var item: SelectedItem
    var autoCommitEnabled: Bool

    init(
        commits: [SelectableWipCommit],
        item: SelectedItem,
        autoCommitEnabled: Bool
    ) {
        self.commits = commits
        self.item = item
        self.autoCommitEnabled = autoCommitEnabled
    }

    var isNotEmpty: Bool { commits.isNotEmpty }
}
