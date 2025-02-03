//
//  BranchListViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation
import Observation

@Observable class BranchListViewModel {
    struct RepositoryInfo: Identifiable, Codable {
        enum Head: Codable {
            case branch(Branch)
            case tag(TagReference)
            case reference(Reference)
        }
        var id: String { url.absoluteString }
        var branches: [Branch] = []
        var stashes: [Stash] = []
        var tags: [TagReference] = []
        var head: Head
        var url: URL
    }

    var repositoryInfos: [RepositoryInfo] = []

    init(repositoryInfos: [RepositoryInfo]) {
        self.repositoryInfos = repositoryInfos
    }
}

