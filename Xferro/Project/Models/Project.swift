//
//  Project.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation
import Observation

@Observable final class Project {
    let isGit: Bool
    let url: URL

    init(isGit: Bool, url: URL) {
        self.isGit = isGit
        self.url = url
    }

}

extension Project: Identifiable, Hashable, Equatable, Codable {
    var id: URL { url }
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
