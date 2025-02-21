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
        lhs.delta.id == rhs.delta.id
    }
    var id: String { delta.id + type.id.formatted() }

    let delta: Diff.Delta
    let type: StatusType
    let repository: Repository

    var oldFileURL: URL? {
        guard let oldFilePath else { return nil }
        return repository.workDir.appendingPathComponent(oldFilePath)
    }
    var newFileURL: URL? {
        guard let newFilePath else { return nil }
        return repository.workDir.appendingPathComponent(newFilePath)
    }

    var oldFilePath: String? {
        delta.oldFile?.path
    }

    var newFilePath: String? {
        delta.newFile?.path
    }
}
