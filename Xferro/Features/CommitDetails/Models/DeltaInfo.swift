//
//  DeltaInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/17/25.
//

import Foundation
import Observation
import SwiftUI

enum StatusType: Int, Identifiable, Hashable {
    var id: Int { rawValue }

    case staged = 0
    case unstaged = 1
    case untracked = 2
}

@Observable final class DeltaInfo: Identifiable, Equatable {
    static func == (lhs: DeltaInfo, rhs: DeltaInfo) -> Bool {
        lhs.id == rhs.id
    }
    var id: String {
        "\(delta.id).\(type.id.formatted()).\(oldFileURL?.path ?? "").\(newFileURL?.path ?? "").\(repository.workDir.path).\(diffInfo?.id ?? "")"
    }

    let delta: Diff.Delta
    let type: StatusType
    let repository: Repository
    var diffInfo: (any DiffInformation)?

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

    var checkState: CheckboxState {
        get {
            return diffInfo?.checkState ?? .unchecked
        } set {
            guard diffInfo != nil else {
                fatalError(.invalid)
            }
            diffInfo!.checkState = newValue
        }
    }

    var statusFileName: String {
        let oldFileName = oldFileURL?.lastPathComponent
        let newFileName = newFileURL?.lastPathComponent
        switch delta.status {
        case .unmodified:
            fatalError(.impossible)
        case .added, .modified, .copied, .untracked:
            if let newFileName {
                return newFileName
            } else {
                fatalError(.impossible)
            }
        case .deleted:
            if let oldFileName {
                return oldFileName
            } else {
                fatalError(.impossible)
            }
        case .renamed, .typeChange:
            if let oldFileName, let newFileName {
                return "\(oldFileName) -> \(newFileName)"
            } else {
                fatalError(.impossible)
            }
        case .ignored, .unreadable, .conflicted:
            fatalError(.unimplemented)
        }
    }

    var statusImageName: String {
        switch delta.status {
        case .unmodified:
            fatalError(.impossible)
        case .added:
            "a.square"
        case .modified:
            "m.square"
        case .copied:
            "c.square"
        case .untracked:
            "questionmark.square"
        case .deleted:
            "d.square"
        case .renamed, .typeChange:
            "r.square"
        case .ignored, .unreadable, .conflicted:
            fatalError(.unimplemented)
        }
    }

    var statusColor: Color {
        switch delta.status {
        case .unmodified:
            fatalError(.impossible)
        case .added, .copied:
            .green
        case .modified:
            .blue
        case .untracked, .deleted:
            .red
        case .renamed, .typeChange:
            .yellow
        case .ignored, .unreadable, .conflicted:
            fatalError(.unimplemented)
        }
    }
}
