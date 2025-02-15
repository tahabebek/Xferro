//
//  CommitViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Observation

@Observable final class CommitViewModel {
    var commit: Commit

    init(commit: Commit) {
        self.commit = commit
    }
}
