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

    init(commits: [SelectableWipCommit], item: SelectedItem) {
        self.commits = commits
        self.item = item
    }

    var isNotEmpty: Bool { commits.isNotEmpty }
}
