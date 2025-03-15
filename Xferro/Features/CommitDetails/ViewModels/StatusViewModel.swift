//
//  StatusViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI
import Observation
import OrderedCollections

@Observable final class StatusViewModel {
    var trackedFiles: OrderedDictionary<String, OldNewFile> = [:]
    var untrackedFiles: OrderedDictionary<String, OldNewFile> = [:]
    var currentFile: OldNewFile? = nil

    var commitSummary: String = ""
    var canCommit: Bool = false

    var repository: Repository?
    var selectableStatus: SelectableStatus?

    func updateStatus(
        newSelectableStatus: SelectableStatus,
        repository: Repository?,
        head: Head
    ) async {
        guard let repository else { return }
        guard newSelectableStatus.repositoryId == repository.idOfRepo else {
            fatalError(.invalid)
        }

        let (newTrackedFiles, newUntrackedFiles) = await getTrackedAndUntrackedFiles(
            repository: repository,
            newSelectableStatus: newSelectableStatus,
            head: head
        )

        if selectableStatus != nil {
            let oldKeys = Set(trackedFiles.values.elements.map(\.key))
            let newKeys =  Set(newTrackedFiles.values.elements.map(\.key))
            let intersectionKeys = oldKeys.intersection(newKeys)
            let missingKeys = oldKeys.subtracting(intersectionKeys)
            let remainingKeys = newKeys.subtracting(intersectionKeys)

            for key in intersectionKeys {
                let oldFile = trackedFiles[key]!
                let newFile = newTrackedFiles[key]!
                if oldFile.status != newFile.status {
                    trackedFiles[key] = newFile
                }
                if case .deleted = newFile.status {
                    // do nothing
                } else {
                    let modifiedDate = FileManager.lastModificationDate(of: newFile.workDirNew!)!
                    if let cachedModificationDate = await lastModifiedCache[newFile.workDirNew!] {
                        if cachedModificationDate != modifiedDate {
                            trackedFiles[key] = newFile
                        } else {
                            // do nothing
                        }
                    } else {
                        trackedFiles[key] = newFile
                        await lastModifiedCache.set(key: newFile.workDirNew!, value: modifiedDate)
                    }
                }
            }
            for key in missingKeys {
                trackedFiles.removeValue(forKey: key)
            }
            for key in remainingKeys {
                trackedFiles[key] = newTrackedFiles[key]!
            }
            untrackedFiles = newUntrackedFiles
            self.repository = repository
            self.selectableStatus = newSelectableStatus
        } else {
            self.trackedFiles = newTrackedFiles
            self.untrackedFiles = newUntrackedFiles
            self.repository = repository
            await MainActor.run {
                self.selectableStatus = newSelectableStatus
            }
        }
    }

    private func getTrackedAndUntrackedFiles(
        repository: Repository,
        newSelectableStatus: SelectableStatus,
        head: Head
    ) async -> (OrderedDictionary<String, OldNewFile>, OrderedDictionary<String, OldNewFile>) {
        var addedFiles: Set<String> = []

        var trackedFiles: OrderedDictionary<String, OldNewFile> = [:]
        var untrackedFiles: OrderedDictionary<String, OldNewFile> = [:]
        let handleDelta: (Repository, Diff.Delta) -> Void = { repository, delta in
            let key = (delta.oldFilePath ?? "") + (delta.newFilePath ?? "")
            if addedFiles.contains(key) {
                return
            }
            addedFiles.insert(key)
            switch delta.status {
            case .unmodified, .ignored:
                fatalError(.invalid)
            case .untracked:
                if let newPath = delta.newFilePath {
                    if FileManager.fileExists(repository.workDir.path +/ newPath) {
                        untrackedFiles[key] = OldNewFile(
                            old: delta.oldFilePath,
                            new: delta.newFilePath,
                            status: delta.status,
                            repository: repository,
                            head: head,
                            key: key
                        )
                    }
                }
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            case .added:
                if let newPath = delta.newFilePath {
                    if FileManager.fileExists(repository.workDir.path +/ newPath) {
                        trackedFiles[key] = OldNewFile(
                            old: delta.oldFilePath,
                            new: delta.newFilePath,
                            status: delta.status,
                            repository: repository,
                            head: head,
                            key: key
                        )
                    }
                }
            case .deleted:
                if let oldPath = delta.oldFilePath {
                    if !FileManager.fileExists(repository.workDir.path +/ oldPath) {
                        trackedFiles[key] = OldNewFile(
                            old: delta.oldFilePath,
                            new: delta.newFilePath,
                            status: delta.status,
                            repository: repository,
                            head: head,
                            key: key
                        )
                    }
                }
            case .modified:
                if let oldPath = delta.oldFilePath,
                   let newPath = delta.newFilePath, oldPath == newPath {
                    if FileManager.fileExists(repository.workDir.path +/ newPath) {
                        trackedFiles[key] = OldNewFile(
                            old: delta.oldFilePath,
                            new: delta.newFilePath,
                            status: delta.status,
                            repository: repository,
                            head: head,
                            key: key
                        )
                    }
                }
            case .renamed, .typeChange, .copied:
                if let newPath = delta.newFilePath {
                    if FileManager.fileExists(repository.workDir.path +/ newPath) {
                        trackedFiles[key] = OldNewFile(
                            old: delta.oldFilePath,
                            new: delta.newFilePath,
                            status: delta.status,
                            repository: repository,
                            head: head,
                            key: key
                        )
                    }
                }
            }
        }
        for statusEntry in newSelectableStatus.statusEntries {
            var handled: Bool = false
            if let stagedDelta = statusEntry.stagedDelta {
                handled = true
                handleDelta(repository, stagedDelta)
            }

            if let unstagedDelta = statusEntry.unstagedDelta {
                handled = true
                handleDelta(repository,unstagedDelta)
            }

            guard handled else {
                fatalError(.unimplemented)
            }
        }
        return (trackedFiles, untrackedFiles)
    }

    func actionTapped(_ action: StatusActionButtonsView.BoxAction) async throws {
        guard let repository else { return }
        switch action {
//        case .splitAndCommit:
//            await commitTapped()
//            fatalError(.unimplemented)
        case .amend:
            try await amendTapped()
        case .commitAndPush:
            try await commitTapped()
            let pushOperation = await PushOpController(remoteOption: .currentBranch, repository: repository)
            try await pushOperation.start()
        case .amendAndPush:
            try await amendTapped()
            fatalError(.unimplemented)
        case .commitAndForcePush:
            try await commitTapped()
            fatalError(.unimplemented)
        case .amendAndForcePush:
            try await amendTapped()
            fatalError(.unimplemented)
        case .stash:
            fatalError(.unimplemented)
        case .popStash:
            fatalError(.unimplemented)
        case .applyStash:
            fatalError(.unimplemented)
        case .discardAll:
            await discardAllTapped()
        case .addCustom:
            fatalError(.unimplemented)
        }
    }

    func trackAllTapped() async {
        for file in untrackedFiles.values {
            await trackTapped(flag: true, file: file)
        }
    }

    func trackTapped(flag: Bool, file: OldNewFile) async {
        guard let repository, let path = file.new else {
            fatalError(.invalid)
        }
        if flag {
            repository.stage(path: path).mustSucceed(repository.gitDir)
        } else {
            repository.unstage(path: path).mustSucceed(repository.gitDir)
        }
    }

    func commitTapped() async throws {
        guard let repository else {
            fatalError(.invalid)
        }
        try await commit(repository: repository, amend: false)
    }

    func splitAndCommitTapped() async -> Commit {
        fatalError(.unimplemented)
    }

    func amendTapped() async throws {
        guard let repository else {
            fatalError(.invalid)
        }

        try await commit(repository: repository, amend: true)
    }

    private func commit(repository: Repository, amend: Bool) async throws {
        GitCLI.executeGit(repository, ["restore", "--staged", "."])
        var filesToWriteBack: [String: String] = [:]
        var filesToAdd: Set<String> = []
        var filesToDelete: Set<String> = []

        for file in trackedFiles.values.elements where file.checkState == .checked {
            guard file.new != nil || file.old != nil else {
                fatalError(.invalid)
            }

            if let new = file.new {
                filesToAdd.insert(new)
            }
            if let old = file.old , old != file.new {
                filesToAdd.insert(old)
            }
        }

        for file in trackedFiles.values.elements where file.checkState == .partiallyChecked {
            guard let hunks = file.diffInfo?.hunks() else {
                fatalError(.invalid)
            }

            let hunkCopies = hunks.map { $0.copy() }
            let originalLines = hunks.flatMap(\.parts).filter({ $0.type == .additionOrDeletion }).flatMap(\.lines)
            let copyLines = hunkCopies.flatMap(\.parts).filter({ $0.type == .additionOrDeletion }).flatMap(\.lines)
            for i in 0..<originalLines.count {
                copyLines[i].isSelected = !originalLines[i].isSelected
            }

            let unselectedLines = copyLines.filter(\.isSelected)
            if unselectedLines.count == 0 {
                fatalError(.impossible)
            }

            switch file.status {
            case .added, .copied, .renamed, .typeChange, .modified:
                guard let workDirNew = file.workDirNew, let new = file.new else {
                    fatalError(.invalid)
                }
                if FileManager.fileExists(workDirNew) {
                    let currentFile = try String(contentsOfFile: workDirNew, encoding: .utf8)
                    filesToWriteBack[workDirNew] = currentFile
                    try! await file.discardLines(lines: unselectedLines, hunks: hunkCopies)
                } else {
                    fatalError(.impossible)
                }
                filesToAdd.insert(new)
            case .deleted:
                guard let old = file.old else {
                    fatalError(.invalid)
                }

                try! await file.discardLines(lines: unselectedLines, hunks: hunkCopies)
                filesToAdd.insert(old)
                filesToDelete.insert(old)
            case .ignored, .unreadable, .unmodified, .untracked:
                fatalError(.invalid)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }

        let addArguments = ["add"] + Array(filesToAdd)
        GitCLI.executeGit(repository, addArguments)
        if amend {
            if commitSummary.isEmptyOrWhitespace {
                GitCLI.executeGit(repository, ["commit", "--amend", "--no-edit"])
            } else {
                GitCLI.executeGit(repository, ["commit", "--amend", "-m", commitSummary])
            }
        } else {
            GitCLI.executeGit(repository, ["commit", "-m", commitSummary])
        }

        for file in trackedFiles.values.elements {
            await diffInfoCache.removeValue(forKey: file.key)
            if let workDirNew = file.workDirNew {
                await lastModifiedCache.removeValue(forKey: workDirNew)
            }
        }
        for (path, content) in filesToWriteBack {
            try! content.write(toFile: path, atomically: true, encoding: .utf8)
        }
        for path in filesToDelete {
            try! FileManager.default.removeItem(atPath: path)
        }
        GitCLI.executeGit(repository, ["restore", "--staged", "."])
        await MainActor.run {
            commitSummary = ""
        }
    }

    func ignoreTapped(file: OldNewFile) async {
        guard let repository else {
            fatalError(.invalid)
        }
        guard let path = file.new else {
            fatalError(.illegal)
        }
        repository.ignore(path)
    }

    func discardTapped(file: OldNewFile) async {
        guard let repository else {
            fatalError(.invalid)
        }
        let oldFile = file.workDirOld
        let newFile = file.workDirNew
        var fileURLs = [URL]()

        if let oldFile, let newFile, oldFile == newFile {
            fileURLs.append(oldFile.fileURL!)
        } else {
            if let oldFile {
                fileURLs.append(oldFile.fileURL!)
            }
            if let newFile {
                fileURLs.append(newFile.fileURL!)
            }
        }
        for fileURL in fileURLs {
            switch file.status {
            case .unmodified, .ignored:
                fatalError(.invalid)
            case .added, .copied, .untracked:
                try! FileManager.removeItem(fileURL)
            case .deleted, .modified, .renamed, .typeChange:
                if fileURL.isDirectory {
                    GitCLI.executeGit(repository, ["restore", fileURL.appendingPathComponent("*").path])
                } else {
                    GitCLI.executeGit(repository, ["restore", fileURL.path])
                }
            case .conflicted, .unreadable:
                fatalError(.unimplemented)
            }
        }
    }

    func discardAlertTitle(file: OldNewFile?) -> String {
        guard let file else {
            return "Are you sure you want to discard all the changes in all the files?"
        }

        var title: String = "Are you sure you want to discard all the changes"
        let oldFilePath = file.old
        let newFilePath = file.new

        if let oldFilePath, let newFilePath, oldFilePath == newFilePath {
            title += " to\n\(oldFilePath)?"
        } else if let oldFilePath, let newFilePath {
            title += " to\n\(oldFilePath), and\n\(newFilePath)?"
        } else if let oldFilePath {
            title += " to\n\(oldFilePath)?"
        } else if let newFilePath {
            title += " to\n\(newFilePath)?"
        }
        return title
    }

    func discardAllTapped() async {
        guard let repository else {
            fatalError(.invalid)
        }
        GitCLI.executeGit(repository, ["add", "."])
        GitCLI.executeGit(repository, ["reset", "--hard"])
    }

    func setInitialSelection() {
        if currentFile == nil {
            var item: OldNewFile?
            if let firstItem = trackedFiles.values.first {
                item = firstItem
            } else if let firstItem = untrackedFiles.values.first {
                item = firstItem
            }
            if let item {
                currentFile = item
            }
        }
    }

    var hasChanges: Bool {
        !trackedFiles.isEmpty || !untrackedFiles.isEmpty
    }

    func selectAll(flag: Bool) async {
        let keys = Set(trackedFiles.values.elements.map(\.key))
        for key in keys {
            if flag, trackedFiles[key]?.checkState == .checked { continue }
            if !flag, trackedFiles[key]?.checkState == .unchecked { continue }
            trackedFiles[key]?.checkState = flag ? .checked : .unchecked
            for line in trackedFiles[key]?.diffInfo?.hunks().flatMap(\.parts).filter({ $0.type != .context }).flatMap(\.lines) ?? [] {
                line.isSelected = flag
            }
        }
    }
}
