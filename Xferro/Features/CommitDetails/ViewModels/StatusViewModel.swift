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
        guard let repository else {
            return
        }
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
                            print("updated tracked file for \(newFile.workDirNew!)")
                            trackedFiles[key] = newFile
                        } else {
                            // do nothing
                        }
                    } else {
                        print("updated uncached tracked file for \(newFile.workDirNew!)")
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
            self.selectableStatus = newSelectableStatus
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
                break
            case .untracked:
                untrackedFiles[key] = OldNewFile(
                        old: delta.oldFilePath,
                        new: delta.newFilePath,
                        status: delta.status,
                        repository: repository,
                        head: head,
                        key: key
                    )
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            default:
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

    func actionTapped(_ action: StatusActionButtonsView.BoxAction) async {
        switch action {
//        case .splitAndCommit:
//            await commitTapped()
//            fatalError(.unimplemented)
        case .amend:
            await amendTapped()
        case .commitAndPush:
            await commitTapped()
            fatalError(.unimplemented)
        case .amendAndPush:
            await amendTapped()
            fatalError(.unimplemented)
        case .commitAndForcePush:
            await commitTapped()
            fatalError(.unimplemented)
        case .amendAndForcePush:
            await amendTapped()
            fatalError(.unimplemented)
        case .stash:
            fatalError(.unimplemented)
        case .popStash:
            fatalError(.unimplemented)
        case .applyStash:
            fatalError(.unimplemented)
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
            repository.stage(path: path).mustSucceed()
        } else {
            repository.unstage(path: path).mustSucceed()
        }
    }

    @discardableResult
    func commitTapped() async -> Commit {
        guard let repository else {
            fatalError(.invalid)
        }
        let commit: Commit = repository.commit(message: commitSummary).mustSucceed()
        commitSummary = ""
        return commit
    }

    func splitAndCommitTapped() async -> Commit {
        fatalError(.unimplemented)
    }

    func amendTapped() async {
        guard let repository else {
            fatalError(.invalid)
        }
        let headCommit: Commit = repository.commit().mustSucceed()
        var newMessage = commitSummary
        if newMessage.isEmptyOrWhitespace {
            newMessage = headCommit.summary
        }

        guard !newMessage.isEmptyOrWhitespace else {
            fatalError(.unsupported)
        }
        repository.amend(message: newMessage).mustSucceed()
        commitSummary = ""
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

    func discardAlertTitle(file: OldNewFile) -> String {
        let oldFilePath = file.old
        let newFilePath = file.new
        var title: String = "Are you sure you want to discard all the changes"

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
}
