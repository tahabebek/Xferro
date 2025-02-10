//
//  RepositoryViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Observation

@Observable final class RepositoryViewModel {
    var repositoryInfo: RepositoryInfo

    init(repositoryInfo: RepositoryInfo) {
        self.repositoryInfo = repositoryInfo
    }
}
