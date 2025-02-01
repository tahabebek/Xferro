//
//  GGViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/30/25.
//

import Foundation
import Observation

@Observable final class GGViewModel {
    var gitGraph: GitGraph
    var config: GitGraphViewConfiguration

    init(gitGraph: GitGraph, config: GitGraphViewConfiguration = .init()) {
        self.gitGraph = gitGraph
        self.config = config
    }
}
