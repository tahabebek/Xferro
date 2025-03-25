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
    var isUntracked: Bool = false

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
            diffInfo?.checkState ?? .checked
        } set {
            Task { @MainActor [weak self] in
                guard let self else { return }
                if diffInfo != nil {
                    diffInfo!.checkState = newValue
                } else {
                    await setDiffInfoForStatus()
                    guard diffInfo != nil else {
                        fatalError(.invalid)
                    }
                    diffInfo!.checkState = newValue
                }
            }
        }
    }

    func discardPart(_ part: DiffHunkPart) {
        guard case .additionOrDeletion = part.type, let hunks = diffInfo?.hunks() else {
            fatalError(.invalid)
        }
        Task {
            do {
                for part in hunks.flatMap(\.parts) {
                    part.selectAll()
                }
                part.unselectAll()
                try await discardLines(lines: hunks.flatMap(\.selectedLines), hunks: hunks)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    func discardLines(lines: [DiffLine], hunks: [DiffHunk]) async throws {
        switch status {
        case .added, .copied:
            guard let newFilePath = new else {
                fatalError(.invalid)
            }
            if lines.isEmpty {
                // this means delete the file
                try FileManager.removeItem(repository.workDir +/ newFilePath)
                return
            }
            let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                repository: repository,
                oldFilePath: newFilePath,
                newFilePath: newFilePath,
                selectedLines: lines,
                allHunks: hunks
            ).resultingFileLines.joined(separator: "\n")
            try result.data(using: .utf8)?.write(to: repository.workDir +/ newFilePath)
        case .modified, .renamed, .typeChange:
            guard let oldFilePath = old, let newFilePath = new else {
                fatalError(.invalid)
            }
            if lines.isEmpty {
                // this means reset the file
                let headFileResult = GitCLI.showHead(repository, oldFilePath)
                guard case .success(let result) = headFileResult else {
                    fatalError(.impossible)
                }

                try result.data(using: .utf8)?.write(to: repository.workDir +/ newFilePath)
                return
            }
            let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                repository: repository,
                oldFilePath: oldFilePath,
                newFilePath: newFilePath,
                selectedLines: lines,
                allHunks: hunks
            ).resultingFileLines.joined(separator: "\n")
            try result.data(using: .utf8)?.write(to: repository.workDir +/ newFilePath)
        case .deleted:
            guard let oldFilePath = old else {
                fatalError(.invalid)
            }
            if lines.isEmpty {
                // this means bring back the file
                let headFileResult = GitCLI.showHead(repository, oldFilePath)
                guard case .success(let result) = headFileResult else {
                    fatalError(.impossible)
                }

                try result.data(using: .utf8)?.write(to: repository.workDir +/ oldFilePath)
                return
            }
            let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                repository: repository,
                oldFilePath: oldFilePath,
                newFilePath: oldFilePath,
                selectedLines: lines,
                allHunks: hunks
            ).resultingFileLines.joined(separator: "\n")
            try result.data(using: .utf8)?.write(to: repository.workDir +/ oldFilePath)
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
                case .modified, .renamed, .typeChange:
                    guard let newFilePath = new, let oldFilePath = old else {
                        fatalError(.invalid)
                    }
                    let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                        repository: repository,
                        oldFilePath: oldFilePath,
                        newFilePath: newFilePath,
                        selectedLines: selectedLines,
                        allHunks: hunkCopies
                    )
                    try result.resultingFileLines.joined(separator: "\n").write(
                        toFile: repository.workDir.path + "/" + newFilePath,
                        atomically: true,
                        encoding: .utf8
                    )
                case .deleted:
                    guard let oldFilePath = old else {
                        fatalError(.invalid)
                    }
                    let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                        repository: repository,
                        oldFilePath: oldFilePath,
                        newFilePath: oldFilePath,
                        selectedLines: selectedLines,
                        allHunks: hunkCopies
                    )
                    try result.resultingFileLines.joined(separator: "\n").write(
                        toFile: repository.workDir.path + "/" + oldFilePath,
                        atomically: true,
                        encoding: .utf8
                    )
                case .added, .copied:
                    guard let newFilePath = new else {
                        fatalError(.invalid)
                    }
                    let result = try await SelectedLinesDiffMaker.makeFileWithSelectedLines(
                        repository: repository,
                        oldFilePath: newFilePath,
                        newFilePath: newFilePath,
                        selectedLines: selectedLines,
                        allHunks: hunkCopies
                    )
                    try result.resultingFileLines.joined(separator: "\n").write(
                        toFile: repository.workDir.path + "/" + newFilePath,
                        atomically: true,
                        encoding: .utf8
                    )
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
            isUntracked = false
            diffInfo = newDiffInfo
        }
    }

    func setDiffInfoForStatus() async {
        switch status {
        case .unmodified, .ignored:
            fatalError(.invalid)
        case .untracked:
            await MainActor.run {
                isUntracked = true
                diffInfo = nil
                return
            }
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
                    await MainActor.run {
                        isUntracked = false
                        diffInfo = cached
                    }
                } else {
                    let newDiffInfo = await createDiffInfo()
                    await diffInfoCache.set(key: workDirOld, value: newDiffInfo)
                    await MainActor.run {
                        isUntracked = false
                        diffInfo = newDiffInfo
                    }
                }
            } else {
                if diffInfo == nil {
                    let newDiffInfo = await createDiffInfo()
                    await diffInfoCache.set(key: workDirOld, value: newDiffInfo)
                    await MainActor.run {
                        isUntracked = false
                        diffInfo = newDiffInfo
                    }
                }
            }
        case .unreadable, .conflicted:
            fatalError(.unimplemented)
        }
    }

    func setDiffInfoComparedToOwner(commit: Commit, owner: any SelectableItem) async {
        let commitPointer = await withUnsafeContinuation { continuation in
            let pointer = repository.withGitObject(commit.oid, type: GIT_OBJECT_COMMIT) {
                return $0
            }.mustSucceed(repository.gitDir)
            continuation.resume(returning: pointer)
        }
        let ownerPointer = await withUnsafeContinuation { continuation in
            let pointer = repository.withGitObject(owner.oid, type: GIT_OBJECT_COMMIT) {
                return $0
            }.mustSucceed(repository.gitDir)
            continuation.resume(returning: pointer)
        }

        let diffInfo = await self.createDiffInfo(commit: commitPointer, parent: ownerPointer)
        await MainActor.run {
            self.diffInfo = diffInfo
        }
    }

    private func createDiffInfo(commit: OpaquePointer, parent: OpaquePointer) async -> any DiffInformation {
        let patchResult = repository.patchMakerFromOwnerToWip(
            oldNewFile: self,
            ownerCommit: parent,
            wipCommit: commit
        )
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
