//
//  Project.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation

class Project: Codable, Hashable, Equatable {
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    init(isGit: Bool, url: URL) {
        self.isGit = isGit
        self.url = url
    }

    let isGit: Bool
    let url: URL
}
