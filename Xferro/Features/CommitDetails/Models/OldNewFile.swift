//
//  OldNewFile.swift
//  Xferro
//
//  Created by Taha Bebek on 3/11/25.
//

import SwiftUI
import Observation
import OrderedCollections

@Observable final class OldNewFile: Identifiable, Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    static func ==(lhs: OldNewFile, rhs: OldNewFile) -> Bool {
        lhs.key == rhs.key
    }

    let id = UUID()
    let old: String?
    let new: String?
    let workDirOld: String?
    let workDirNew: String?
    let status: Diff.Delta.Status
    let repository: Repository
    let statusFileName: String
    let statusColor: Color
    let statusImageName: String
    let head: Head
    let key: String
    var diffInfo: (any DiffInformation)?

    init(
        old: String?,
        new: String?,
        status: Diff.Delta.Status,
        repository: Repository,
        head: Head,
        key: String,
        diffInfo: (any DiffInformation)? = nil
    ) {
        self.old = old
        self.new = new
        self.workDirOld = old != nil ? repository.workDir.appendingPathComponent(old!).path : nil
        self.workDirNew = new != nil ? repository.workDir.appendingPathComponent(new!).path : nil
        self.status = status
        self.repository = repository
        self.head = head
        self.diffInfo = diffInfo

        self.statusFileName = switch status {
        case .unmodified:
            fatalError(.impossible)
        case .added, .modified, .copied, .untracked:
            if let new {
                URL(filePath: new).lastPathComponent
            } else {
                fatalError(.impossible)
            }
        case .deleted:
            if let old {
                URL(filePath: old).lastPathComponent
            } else {
                fatalError(.impossible)
            }
        case .renamed, .typeChange:
            if let old, let new {
                "\(URL(filePath: old).lastPathComponent) -> \(URL(filePath: new).lastPathComponent)"
            } else {
                fatalError(.impossible)
            }
        case .ignored, .unreadable, .conflicted:
            fatalError(.unimplemented)
        }

        self.statusColor = switch status {
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

        self.statusImageName = switch status {
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
        self.key = key
    }

    var checkState: CheckboxState {
        get {
            return diffInfo?.checkState ?? .checked
        } set {
            guard diffInfo != nil else {
                fatalError(.invalid)
            }
            diffInfo!.checkState = newValue
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

        switch status {
        case .added, .copied, .renamed, .typeChange:
            guard let newFilePath = new else {
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
            guard let oldFilePath = old, let newFilePath = new else {
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
            guard let oldFilePath = old else {
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
                if hunkline.id == line.id {
                    hunkline.isSelected = false
                } else {
                    hunkline.isSelected = true
                }
            }

            let selectedLines = lines.filter(\.isSelected)

            do {
                switch status {
                case .added, .copied, .renamed, .typeChange, .modified, .deleted:
                    guard let newFilePath = new else {
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

    private func actuallySetDiffInfo(path: String, modifiedDate: Date) async {
        let newDiffInfo = await createDiffInfo()
        await diffInfoCache.set(key: path, value: newDiffInfo)
        await lastModifiedCache.set(key: path, value: modifiedDate)
        await MainActor.run {
            diffInfo = newDiffInfo
        }
        print("setDiffInfo for \(path)")
    }

    func setDiffInfo() async {
        switch status {
        case .unmodified, .ignored, .untracked:
            fatalError(.invalid)
        case .added, .modified, .renamed, .copied, .typeChange:
            guard let workDirNew else {
                fatalError(.invalid)
            }
            if let cachedModificationDate = await lastModifiedCache[workDirNew] {
                guard let modifiedDate = FileManager.lastModificationDate(of: workDirNew) else {
                    fatalError(.invalid)
                }
                if cachedModificationDate != modifiedDate {
                    await actuallySetDiffInfo(path: workDirNew, modifiedDate: modifiedDate)
                } else {
                    if diffInfo == nil {
                        await actuallySetDiffInfo(path: workDirNew, modifiedDate: modifiedDate)
                    }
                }
            } else {
                guard let modifiedDate = FileManager.lastModificationDate(of: workDirNew) else {
                    fatalError(.invalid)
                }
                await actuallySetDiffInfo(path: workDirNew, modifiedDate: modifiedDate)
            }
        case .deleted:
            guard let workDirOld else {
                fatalError(.invalid)
            }
            if diffInfo == nil {
                if let cached = await diffInfoCache[workDirOld] {
                    diffInfo = cached
                } else {
                    let newDiffInfo = await createDiffInfo()
                    await diffInfoCache.set(key: workDirOld, value: newDiffInfo)
                    await MainActor.run {
                        diffInfo = newDiffInfo
                    }
                    print("setDiffInfo for \(workDirOld)")
                }
            } else {
                if diffInfo == nil {
                    let newDiffInfo = await createDiffInfo()
                    await diffInfoCache.set(key: workDirOld, value: newDiffInfo)
                    await MainActor.run {
                        diffInfo = newDiffInfo
                    }
                    print("setDiffInfo for \(workDirOld)")
                }
            }
        case .unreadable, .conflicted:
            fatalError(.unimplemented)
        }
    }

    private func createDiffInfo() async -> any DiffInformation {
        let patchResult = repository.patchMakerForAFileInTeWorkspaceComparedToHead(head: head, oldNewFile: self)

        switch patchResult {
        case .noDifference:
            return NoDiffInfo(statusFileName: statusFileName)
        case .binary:
            return BinaryDiffInfo(statusFileName: statusFileName)
        case .diff(let patchMaker):
            let patch = patchMaker.makePatch()
            var newHunks = [DiffHunk]()
            let hunkCount = patch.hunkCount
            for index in 0..<hunkCount {
                if let hunk = patch.hunk(
                    at: index,
                    oldFilePath: old,
                    newFilePath: new,
                    status: status,
                    repository: repository
                ) {
                    newHunks.append(hunk)
                }
            }
            return DiffInfo(
                hunks: newHunks,
                oldFilePath: old,
                newFilePath: new,
                addedLinesCount: patch.addedLinesCount,
                deletedLinesCount: patch.deletedLinesCount,
                statusFileName: statusFileName
            )
        }
    }
}
