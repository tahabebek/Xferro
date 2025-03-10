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

    func discardPart(_ part: DiffHunkPart) {
        guard case .additionOrDeletion = part.type else {
            fatalError(.invalid)
        }
        Task {
            do {
                let selectedLines = part.lines.filter(\.isSelected)
                try await discardLines(selectedLines)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    private func discardLines(_ lines: [DiffLine]) async throws {
        guard let diffInfo else {
            fatalError(.invalid)
        }

        let hunks = diffInfo.hunks()

        switch delta.status {
        case .added, .copied, .renamed, .typeChange:
            guard let newFilePath = delta.newFile?.path else {
                fatalError(.invalid)
            }
            let diff = try await SelectedLinesDiffMaker.makeDiff(
                repository: repository,
                filePath: newFilePath,
                selectedLines: lines,
                allHunks: hunks,
                reverse: true
            )
            try PatchCLI.executePatch(
                diff: diff,
                inputFilePath: nil,
                outputFilePath: repository.workDir.path + "/" + newFilePath,
                operation: .create
            )
        case .modified:
            guard let oldFilePath = delta.oldFile?.path, let newFilePath = delta.newFile?.path else {
                fatalError(.invalid)
            }
            let diff = try await SelectedLinesDiffMaker.makeDiff(
                repository: repository,
                filePath: newFilePath,
                selectedLines: lines,
                allHunks: hunks,
                reverse: true
            )
            try PatchCLI.executePatch(
                diff: diff,
                inputFilePath: repository.workDir.path + "/" + oldFilePath,
                outputFilePath: repository.workDir.path + "/" + newFilePath,
                operation: .modify
            )
        case .deleted:
            guard let oldFilePath = delta.oldFile?.path else {
                fatalError(.invalid)
            }
            let diff = try await SelectedLinesDiffMaker.makeDiff(
                repository: repository,
                filePath: oldFilePath,
                selectedLines: lines,
                allHunks: hunks,
                reverse: true
            )
            try PatchCLI.executePatch(
                diff: diff,
                inputFilePath: repository.workDir.path + "/" + oldFilePath,
                outputFilePath: nil,
                operation: .delete
            )
        case .ignored, .unreadable, .unmodified, .untracked:
            fatalError(.invalid)
        case .conflicted:
            fatalError(.unimplemented)
        }
    }

    func discardLine(_ line: DiffLine) {
        guard line.isAdditionOrDeletion else {
            fatalError(.invalid)
        }
        guard let diffInfo else {
            fatalError(.invalid)
        }

        Task {
            let hunkCopies = diffInfo.hunks().map { $0.copy() }
            let lines = hunkCopies.flatMap(\.parts).filter({ $0.type == .additionOrDeletion }).flatMap(\.lines)
            for hunkline in lines {
                if hunkline == line {
                    hunkline.isSelected = false
                } else {
                    hunkline.isSelected = true
                }
            }

            let selectedLines = lines.filter(\.isSelected)

            do {
                switch delta.status {
                case .added, .copied, .renamed, .typeChange, .modified, .deleted:
                    guard let newFilePath = delta.newFile?.path else {
                        fatalError(.invalid)
                    }
                    let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                        repository: repository,
                        filePath: newFilePath,
                        selectedLines: selectedLines,
                        allHunks: hunkCopies
                    )
                    try result.resultingFileLines.joined(separator: "\n").write(toFile: repository.workDir.path + "/" + newFilePath, atomically: true, encoding: .utf8)
                case .ignored, .unreadable, .unmodified, .untracked:
                    fatalError(.invalid)
                case .conflicted:
                    fatalError(.unimplemented)
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}
