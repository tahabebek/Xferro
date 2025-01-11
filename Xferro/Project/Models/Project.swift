//
//  Project.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation

struct Project: Codable, Hashable, Equatable {
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    let isGit: Bool
    let url: URL
    let commits: [Commit]
}
