//
//  DeltaInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/17/25.
//

import Foundation

struct DeltaInfo: Identifiable, Equatable, Hashable {
    enum StatusType: Int, Identifiable, Hashable {
        var id: Int { rawValue }

        case staged = 0
        case unstaged = 1
        case untracked = 2
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    var id: String { delta.id + type.id.formatted() }

    let delta: Diff.Delta
    let type: StatusType
    let repository: Repository

    init(delta: Diff.Delta, type: StatusType, repository: Repository) {
        self.delta = delta
        self.type = type
        self.repository = repository
    }

    var oldFileURL: URL? {
        guard let oldFilePath else { return nil }
        return repository.workDir.appendingPathComponent(oldFilePath)
    }
    var newFileURL: URL? {
        guard let newFilePath else { return nil }
        return repository.workDir.appendingPathComponent(newFilePath)
    }

    var oldFilePath: String? {
        delta.oldFilePath
    }

    var newFilePath: String? {
        delta.newFilePath
    }
}
