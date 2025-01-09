//
//  Project.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation

struct Project: Codable {
    let isGit: Bool
    let url: URL
    let commits: [Commit]
}
