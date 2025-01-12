//
//  OnDiskGit.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

final class OnDiskGit {
    public let repository: Repository

    init(url: URL) {
        let result = Repository.at(url)

        switch result {
            case .success(let repository):
            self.repository = repository
        case .failure(let error):
            fatalError("Failed to initialize repository at \(url): \(error)")
        }
    }
}
