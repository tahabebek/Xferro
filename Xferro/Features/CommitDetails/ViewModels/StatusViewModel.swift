//
//  StatusViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Combine
import SwiftUI
import Observation
import OrderedCollections

@Observable final class StatusViewModel {
    var trackedFiles: [OldNewFile] = []
    var untrackedFiles: [OldNewFile] = []
    var currentFile: OldNewFile? = nil

    var commitSummary: String = ""
    var canCommit: Bool = false
    var shouldAddRemoteBranch: Bool = false
    var repository: Repository?
    var remotes: [Remote]?
    var selectableStatus: SelectableStatus?
    var refreshRemoteSubject: PassthroughSubject<Void, Never>?
    var addRemoteTitle: String = ""

    func getLastSelectedRemoteIndex(buttonTitle: String) -> Int {
        guard let remotes else {
            fatalError(.illegal)
        }

        let userDefaults = UserDefaults.standard
        if let remote = userDefaults.string(forKey: selectedRemoteKey(buttonTitle: buttonTitle)) {
            return Int(remote)!
        } else {
            if remotes.count > 0 {
                if let originIndex = remotes.firstIndex(where: { $0.name == "origin" }) {
                    setLastSelectedRemote(originIndex, buttonTitle: buttonTitle)
                    return originIndex
                } else if let upstreamIndex = remotes.firstIndex(where: { $0.name == "upstream" }) {
                    setLastSelectedRemote(upstreamIndex, buttonTitle: buttonTitle)
                    return upstreamIndex
                }
            }
        }
        return 0
    }

    func setLastSelectedRemote(_ index: Int, buttonTitle: String) {
        UserDefaults.standard.set(index, forKey: selectedRemoteKey(buttonTitle: buttonTitle))
    }

    private func selectedRemoteKey(buttonTitle: String) -> String {
        guard let selectableStatus else {
            fatalError(.illegal)
        }
        return selectableStatus.id + ".\(buttonTitle)"
    }

    private var unsortedTrackedFiles: OrderedDictionary<String, OldNewFile> = [:] {
        didSet {
            trackedFiles = Array(unsortedTrackedFiles.values.elements).sorted { $0.statusFileName < $1.statusFileName }
        }
    }

    private var unsortedUntrackedFiles: OrderedDictionary<String, OldNewFile> = [:]{
        didSet {
            untrackedFiles = Array(unsortedUntrackedFiles.values.elements).sorted { $0.key < $1.key }
        }
    }

    func updateStatus(
        newSelectableStatus: SelectableStatus,
        repository: Repository?,
        head: Head,
        remotes: [Remote],
        refreshRemoteSubject: PassthroughSubject<Void, Never>
    ) async {
        guard let repository else { return }
        guard newSelectableStatus.repositoryId == repository.idOfRepo else {
            fatalError(.invalid)
        }
        self.refreshRemoteSubject = refreshRemoteSubject

        let (newTrackedFiles, newUntrackedFiles) = await getTrackedAndUntrackedFiles(
            repository: repository,
            newSelectableStatus: newSelectableStatus,
            head: head
        )

        if selectableStatus != nil {
            let oldKeys = Set(unsortedTrackedFiles.values.elements.map(\.key))
            let newKeys =  Set(newTrackedFiles.values.elements.map(\.key))
            let intersectionKeys = oldKeys.intersection(newKeys)
            let missingKeys = oldKeys.subtracting(intersectionKeys)
            let remainingKeys = newKeys.subtracting(intersectionKeys)

            for key in intersectionKeys {
                let oldFile = unsortedTrackedFiles[key]
                let newFile = newTrackedFiles[key]
                #warning("sometimes these are nil, investigate why, they shouldn't be nil")
                guard let oldFile, let newFile else { continue }

                if oldFile.status != newFile.status {
                    Task { @MainActor in
                        unsortedTrackedFiles[key] = newFile
                    }
                }
                if case .deleted = newFile.status {
                    // do nothing
                } else {
                    let modifiedDate = FileManager.lastModificationDate(of: newFile.workDirNew!)!
                    if let cachedModificationDate = await lastModifiedCache[newFile.workDirNew!] {
                        if cachedModificationDate != modifiedDate {
                            Task { @MainActor in
                                unsortedTrackedFiles[key] = newFile
                            }
                        } else {
                            // do nothing
                        }
                    } else {
                        Task { @MainActor in
                            unsortedTrackedFiles[key] = newFile
                        }
                        await lastModifiedCache.set(key: newFile.workDirNew!, value: modifiedDate)
                    }
                }
            }
            Task { @MainActor in
                for key in missingKeys {
                    unsortedTrackedFiles.removeValue(forKey: key)
                }
                for key in remainingKeys {
                    unsortedTrackedFiles[key] = newTrackedFiles[key]!
                }
                unsortedUntrackedFiles = newUntrackedFiles
                self.repository = repository
                self.remotes = remotes
                self.selectableStatus = newSelectableStatus
            }
        } else {
            Task { @MainActor in
                self.unsortedTrackedFiles = newTrackedFiles
                self.unsortedUntrackedFiles = newUntrackedFiles
                self.repository = repository
                self.remotes = remotes
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

    func onAmend() async throws {
        try await amendTapped()
    }

    func onAddRemote(
        fetchURLString: String,
        pushURLString: String,
        remoteName: String
    ) async {
        guard let repository else {
            fatalError(.invalid)
        }

        Task { @MainActor in
            shouldAddRemoteBranch = false
        }

        guard let fetchURL = URL(string: fetchURLString) else {
            return
        }
        do {
            try repository.addRemote(named: remoteName, url: fetchURL)
            if let remote = repository.remote(named: remoteName) {
                try remote.updatePushURLString(pushURLString)
            }
            remotes?.append(Remote(name: remoteName, repository: repository.pointer)!)
            remotes?.sort { $0.name! < $1.name! }
            if let index = remotes?.firstIndex(where: { $0.name == remoteName }) {
                setLastSelectedRemote(index, buttonTitle: "push")
            }
            refreshRemoteSubject?.send()
        } catch let error as RepoError {
            Task { @MainActor in
                AppDelegate.showErrorMessage(error: error)
            }
        } catch {
            Task { @MainActor in
                AppDelegate.showErrorMessage(error: .unexpected)
            }
        }
    }

    func onCommitAndPush(remote: Remote?) async throws {
        try await tryCommitAndPush(remote: remote, pushType: .normal)
    }

    func onCommitAndForcePushWithLease(remote: Remote?) async throws {
        try await tryCommitAndPush(remote: remote, pushType: .forceWithLease)
    }

    private func tryCommitAndPush(remote: Remote?, pushType: Repository.PushType) async throws {
        guard let repository else {
            fatalError(.invalid)
        }

        if let remote {
            try await actuallyCommitAndPush(remote: remote, repository: repository, pushType: pushType)
        } else {
            Task { @MainActor in
                addRemoteTitle = "This repository doesn't have a remote, add one to push changes to the server"
                shouldAddRemoteBranch = true
            }
        }
    }

    private func actuallyCommitAndPush(
        remote: Remote,
        repository: Repository,
        pushType: Repository.PushType
    ) async throws {
        let head = Head.of(repository)
        guard case .branch(let currentBranch, _) = head else {
            throw RepoError.detachedHead
        }

        try await commitTapped()
        let pushOperation = await PushOpController(
            localBranch: currentBranch,
            remote: remote,
            repository: repository,
            pushType: pushType
        )
        try await pushOperation.start()

    }

    func onAmendAndPush(remote: Remote?) async throws {
        try await tryAmendAndPush(remote: remote, pushType: .normal)
    }

    func onAmendAndForcePushWithLease(remote: Remote?) async throws {
        try await tryAmendAndPush(remote: remote, pushType: .forceWithLease)
    }

    private func tryAmendAndPush(remote: Remote?, pushType: Repository.PushType) async throws {
        guard let repository else {
            fatalError(.unimplemented)
        }

        if let remote {
            try await actuallyAmendAndPush(remote: remote, repository: repository, pushType: pushType)
        } else {
            Task { @MainActor in
                addRemoteTitle = "This repository doesn't have a remote, add one to push changes to the server"
                shouldAddRemoteBranch = true
            }
        }
    }

    private func actuallyAmendAndPush(remote: Remote, repository: Repository, pushType: Repository.PushType) async throws {
        try await amendTapped()
        
        let head = Head.of(repository)
        guard case .branch(let currentBranch, _) = head else {
            throw RepoError.detachedHead
        }
        let pushOperation = await PushOpController(
            localBranch: currentBranch,
            remote: remote,
            repository: repository,
            pushType: pushType
        )
        try await pushOperation.start()
    }

    func addRemoteTapped() async throws {
        Task { @MainActor in
            addRemoteTitle = "Add a new remote"
            shouldAddRemoteBranch = true
        }
    }

    func onStash() async throws {
        fatalError(.unimplemented)
    }

    func onPopStash() async throws {
        fatalError(.unimplemented)
    }

    func onApplyStash(stash: SelectableStash) async throws {
        fatalError(.unimplemented)
    }

    func trackAllTapped() async {
        for file in unsortedUntrackedFiles.values {
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
        try GitCLI.executeGit(repository, ["restore", "--staged", "."])
        var filesToWriteBack: [String: String] = [:]
        var filesToAdd: Set<String> = []
        var filesToDelete: Set<String> = []

        for file in unsortedTrackedFiles.values.elements where file.checkState == .checked {
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

        for file in unsortedTrackedFiles.values.elements where file.checkState == .partiallyChecked {
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
        try GitCLI.executeGit(repository, addArguments)
        if amend {
            if commitSummary.isEmptyOrWhitespace {
                try GitCLI.executeGit(repository, ["commit", "--amend", "--no-edit"])
            } else {
                try GitCLI.executeGit(repository, ["commit", "--amend", "-m", commitSummary])
            }
        } else {
            try GitCLI.executeGit(repository, ["commit", "-m", commitSummary])
        }

        for file in unsortedTrackedFiles.values.elements {
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
        try GitCLI.executeGit(repository, ["restore", "--staged", "."])
        Task { @MainActor in
            commitSummary = ""
            currentFile = nil
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
                    try! GitCLI.executeGit(repository, ["restore", fileURL.appendingPathComponent("*").path])
                } else {
                    try! GitCLI.executeGit(repository, ["restore", fileURL.path])
                }
            case .conflicted, .unreadable:
                fatalError(.unimplemented)
            }
        }

        if file == currentFile {
            Task { @MainActor in
                currentFile = nil
                setInitialSelection()
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

    func discardAllTapped() async throws {
        guard let repository else {
            fatalError(.invalid)
        }
        try GitCLI.executeGit(repository, ["add", "."])
        try GitCLI.executeGit(repository, ["reset", "--hard"])
        Task { @MainActor in
            currentFile = nil
        }
    }

    func setInitialSelection() {
        if currentFile == nil {
            var item: OldNewFile?
            if let firstItem = trackedFiles.first {
                item = firstItem
            } else if let firstItem = untrackedFiles.first {
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
        let keys = Set(unsortedTrackedFiles.values.elements.map(\.key))
        for key in keys {
            if flag, unsortedTrackedFiles[key]?.checkState == .checked { continue }
            if !flag, unsortedTrackedFiles[key]?.checkState == .unchecked { continue }
            unsortedTrackedFiles[key]?.checkState = flag ? .checked : .unchecked
            for line in unsortedTrackedFiles[key]?.diffInfo?.hunks().flatMap(\.parts)
                .filter({ $0.type != .context }).flatMap(\.lines) ?? [] {
                line.isSelected = flag
            }
        }
    }
}
