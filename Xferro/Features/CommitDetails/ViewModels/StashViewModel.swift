//
//  StashViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Observation

@Observable final class StashViewModel {
    var stash: Stash

    init(stash: Stash) {
        self.stash = stash
    }
}
