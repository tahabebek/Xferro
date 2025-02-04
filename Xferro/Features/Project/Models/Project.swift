//
//  Project.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation
import Observation

@Observable class Project: Codable {
    let isGit: Bool
    let url: URL

    init(isGit: Bool, url: URL) {
        self.isGit = isGit
        self.url = url
    }

    enum CodingKeys: CodingKey {
        case isGit
        case url
    }

    // Encoding method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isGit, forKey: .isGit)
        try container.encode(url, forKey: .url)
    }

    // Decoding initializer
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isGit = try container.decode(Bool.self, forKey: .isGit)
        url = try container.decode(URL.self, forKey: .url)
    }
}

extension Project: Identifiable, Hashable, Equatable {
    var id: URL { url }
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
