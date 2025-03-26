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
    var conflictedFiles: [OldNewFile] = []

    var currentFile: OldNewFile? = nil

    var commitSummary: String = ""
    var canCommit: Bool = false
    var shouldAddRemoteBranch: Bool = false
    var repositoryInfo: RepositoryInfo?
    var selectableStatus: SelectableStatus?
    var refreshRemoteSubject: PassthroughSubject<Void, Never>?
    var addRemoteTitle: String = ""
    @ObservationIgnored private(set) var conflictType: ConflictType?

    func getLastSelectedRemoteIndex(buttonTitle: String) -> Int {
        guard let remotes = repositoryInfo?.remotes else {
            fatalError(.invalid)
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

    private var unsortedConflictedFiles: OrderedDictionary<String, OldNewFile> = [:]{
        didSet {
            conflictedFiles = Array(unsortedConflictedFiles.values.elements).sorted { $0.key < $1.key }
        }
    }

    func updateStatus(
        newSelectableStatus: SelectableStatus,
        repositoryInfo: RepositoryInfo?,
        refreshRemoteSubject: PassthroughSubject<Void, Never>
    ) {
        guard let repositoryInfo else { return }
        guard newSelectableStatus.repositoryId == repositoryInfo.repository.idOfRepo else {
            fatalError(.invalid)
        }

        let conflictedEntries =  newSelectableStatus.statusEntries.filter { entry in
            entry.deltas.contains(where: { delta in
                delta.status == .conflicted
            })
        }

        Task {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.refreshRemoteSubject = refreshRemoteSubject
            }

            guard conflictedEntries.isEmpty else {
                await updateStatusWithConflicts(
                    newSelectableStatus: newSelectableStatus,
                    repositoryInfo: repositoryInfo,
                    conflictedEntries: conflictedEntries
                )
                return
            }

            conflictType = nil

            let (newTrackedFiles, newUntrackedFiles) = await getTrackedAndUntrackedFiles(
                repository: repositoryInfo.repository,
                newSelectableStatus: newSelectableStatus,
                head: repositoryInfo.head
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
                        await MainActor.run {
                            unsortedTrackedFiles[key] = newFile
                        }
                    }
                    if case .deleted = newFile.status {
                        // do nothing
                    } else {
                        let modifiedDate = FileManager.lastModificationDate(of: newFile.workDirNew!)!
                        if let cachedModificationDate = await lastModifiedCache[newFile.workDirNew!] {
                            if cachedModificationDate != modifiedDate {
                                await MainActor.run {
                                    unsortedTrackedFiles[key] = newFile
                                }
                            } else {
                                // do nothing
                            }
                        } else {
                            await MainActor.run {
                                unsortedTrackedFiles[key] = newFile
                            }
                            await lastModifiedCache.set(key: newFile.workDirNew!, value: modifiedDate)
                        }
                    }
                }
                await MainActor.run {
                    for key in missingKeys {
                        unsortedTrackedFiles.removeValue(forKey: key)
                    }
                    for key in remainingKeys {
                        unsortedTrackedFiles[key] = newTrackedFiles[key]!
                    }
                    unsortedUntrackedFiles = newUntrackedFiles
                    self.repositoryInfo = repositoryInfo
                    self.selectableStatus = newSelectableStatus
                }
            } else {
                await MainActor.run {
                    self.unsortedTrackedFiles = newTrackedFiles
                    self.unsortedUntrackedFiles = newUntrackedFiles
                    self.repositoryInfo = repositoryInfo
                    self.selectableStatus = newSelectableStatus
                }
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
            case .unmodified, .ignored, .conflicted:
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

    private func updateStatusWithConflicts(
        newSelectableStatus: SelectableStatus,
        repositoryInfo: RepositoryInfo,
        conflictedEntries: [StatusEntry]
    ) async {
        guard let conflictOperationInProgress = repositoryInfo.repository.conflictOperationInProgress() else {
            fatalError(.invalid)
        }

        conflictType = conflictOperationInProgress

        var addedFiles: Set<String> = []
        var conflictedFiles: OrderedDictionary<String, OldNewFile> = [:]

        let handleDelta: (RepositoryInfo, Diff.Delta) -> Void = { repositoryInfo, delta in
            let key = (delta.oldFilePath ?? "") + (delta.newFilePath ?? "")
            if addedFiles.contains(key) {
                return
            }
            addedFiles.insert(key)
            let file = OldNewFile(
                old: delta.oldFilePath,
                new: delta.newFilePath,
                status: delta.status,
                repository: repositoryInfo.repository,
                head: repositoryInfo.head,
                key: key
            )
            file.conflictText = try! String(contentsOfFile: file.workDirNew!, encoding: .utf8)
            conflictedFiles[key] = file
        }

        for statusEntry in conflictedEntries {
            var handled: Bool = false
            if let stagedDelta = statusEntry.stagedDelta {
                handled = true
                handleDelta(repositoryInfo, stagedDelta)
            }

            if let unstagedDelta = statusEntry.unstagedDelta {
                handled = true
                handleDelta(repositoryInfo,unstagedDelta)
            }

            guard handled else {
                fatalError(.unimplemented)
            }
        }

        Task { @MainActor in
            self.unsortedConflictedFiles = conflictedFiles
            self.repositoryInfo = repositoryInfo
            self.selectableStatus = newSelectableStatus
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
}

// MARK: - User Actions

extension StatusViewModel {
    func addRemoteTapped() {
        Task { @MainActor in
            addRemoteTitle = "Add a new remote"
            shouldAddRemoteBranch = true
        }
    }

    func actualAddRemoteTapped(fetchURLString: String, pushURLString: String, remoteName: String) {
        Task {
            await addRemote(
                fetchURLString: fetchURLString,
                pushURLString: pushURLString,
                remoteName: remoteName
            )
        }
    }

    func fetchTapped(fetchType: Repository.FetchType) {
        Task {
            await fetch(fetchType: fetchType)
        }
    }

    func pullTapped(pullType: Repository.PullType) {
        Task {
            await pull(pullType: pullType)
        }
    }

    func pushTapped(branchName: String? = nil, remote: Remote?, pushType: Repository.PushType) {
        Task {
            await push(branchName: branchName, remote: remote, pushType: pushType)
        }
    }

    func forcePushWithLeaseTapped(branchName: String? = nil, remote: Remote?) {
        Task {
            await push(branchName: branchName, remote: remote, pushType: .forceWithLease)
        }
    }

    func commitTapped() {
        Task {
            await commit()
        }
    }

    func amendTapped() {
        Task {
            await amend()
        }
    }

    func splitAndCommitTapped() {
        Task {
            await splitAndCommit()
        }
    }

    func commitAndPushTapped(remote: Remote?) {
        Task {
            await commitAndPush(remote: remote)
        }
    }

    func commitAndForcePushWithLeaseTapped(remote: Remote?) {
        Task {
            await commitAndForcePushWithLease(remote: remote)
        }
    }

    func amendAndPushTapped(remote: Remote?) {
        Task {
            await tryAmendAndPush(remote: remote, pushType: .normal)
        }
    }

    func amendAndForcePushWithLeaseTapped(remote: Remote?) {
        Task {
            await tryAmendAndPush(remote: remote, pushType: .forceWithLease)
        }
    }

    func ignoreTapped(file: OldNewFile) {
        Task {
            await ignore(file: file)
        }
    }

    func trackTapped(flag: Bool, file: OldNewFile) {
        Task {
            await track(flag: flag, file: file)
        }
    }

    func trackAllTapped() {
        Task {
            await trackAll()
        }
    }

    func stashTapped() {
        Task {
            await stash()
        }
    }

    func popStashTapped() {
        Task {
            await popStash()
        }
    }

    func applyStashTapped(stash: SelectableStash) {
        Task {
            await applyStash(stash: stash)
        }
    }

    func discardTapped(file: OldNewFile) {
        Task {
            await discard(file: file)
        }
    }

    func discardAllTapped() {
        Task {
            await discardAll()
        }
    }

    func selectAllTapped(flag: Bool) {
        Task { @MainActor in
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

    func continueMergeTapped() {
    }

    func abortMergeTapped() {
    }

    func continueRebaseTapped() {
    }

    func abortRebaseTapped() {
    }
}

// MARK: Git Operations
fileprivate extension StatusViewModel {
    func fetch(fetchType: Repository.FetchType) async {
        guard let repositoryInfo else { fatalError(.invalid) }
        Task {
            switch fetchType {
            case .remote(let remote):
                guard let remote else {
                    Task { @MainActor in
                        addRemoteTitle = "This repository doesn't have a remote, you need to add one in order to fetch the changes"
                        shouldAddRemoteBranch = true
                    }
                    return
                }
                await withActivityOperation(
                    title: "Fetching \(remote.name ?? "remote")..",
                    successMessage: "Fetched \(remote.name ?? "remote")"
                ) {
                    try GitCLI.execute(repositoryInfo.repository, ["fetch", remote.name!, "--prune"])
                }
            case .all:
                await withActivityOperation(
                    title: "Fetching all remotes",
                    successMessage: "Fetched all remotes"
                ) {
                    try GitCLI.execute(repositoryInfo.repository, ["fetch", "--all", "--prune"])
                }
            }
        }
    }

    func pull(pullType: Repository.PullType) async {
        guard let repositoryInfo else { fatalError(.invalid) }
        guard case .branch = repositoryInfo.head else { fatalError(.invalid) }

        guard (repositoryInfo.repository.config ?? GitConfig.default)!.branchRemote(repositoryInfo.head.name) != nil else {
            Task { @MainActor in
                AppDelegate.showErrorMessage(
                    error: RepoError.unexpected(
                        "This repository doesn't have a remote, you need to add one in order to pull the changes"
                    )
                )
            }
            return
        }

        switch pullType {
        case .merge:
            await withActivityOperation(
                title: "Pulling branch \(repositoryInfo.head.name) (merge)..",
                successMessage: "Pulled branch \(repositoryInfo.head.name) (merge).."
            ) {
                try GitCLI.execute(repositoryInfo.repository, ["pull", "--no-rebase"])
            }
        case .rebase:
            await withActivityOperation(
                title: "Pulling branch \(repositoryInfo.head.name) (rebase)..",
                successMessage: "Pulling branch \(repositoryInfo.head.name) (rebase).."
            ) {
                try GitCLI.execute(repositoryInfo.repository, ["pull", "--rebase",])
            }
        }
        Task { @MainActor in
            await repositoryInfo.refreshStatus()
        }
    }

    func push(
        branchName: String? = nil /* pass nil to push the current branch */,
        remote: Remote?,
        pushType: Repository.PushType
    ) async {
        guard let repositoryInfo else { fatalError(.invalid) }
        guard let remote else {
            Task { @MainActor in
                addRemoteTitle = "This repository doesn't have a remote, you need to add one in order to push the changes"
                shouldAddRemoteBranch = true
            }
            return
        }

        if let branchName {
            guard let branch = repositoryInfo.repository.branch(named: branchName).mustSucceed(repositoryInfo.repository.gitDir) else {
                Task { @MainActor in
                    addRemoteTitle = "There is no branch named \(branchName) in the repository"
                    shouldAddRemoteBranch = true
                }
                return
            }
            await withActivityOperation(
                title: "Pushing \(branch.name) to \(remote)..",
                successMessage: "Pushed \(branch.name) to \(remote)"
            ) {
                let pushOperation = await PushOpController(
                    localBranch: branch,
                    remote: remote,
                    repository: repositoryInfo.repository,
                    pushType: pushType
                )
                try await pushOperation.start()

            }
        } else {
            guard case .branch(let currentBranch, _) = repositoryInfo.head else {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(error: RepoError.unexpected("Push failed, because the head is detached"))
                }
                return
            }
            await withActivityOperation(
                title: "Pushing \(currentBranch.name) to \(remote.name!)..",
                successMessage: "Pushed \(currentBranch.name) to \(remote.name!)"
            ) {
                let pushOperation = await PushOpController(
                    localBranch: currentBranch,
                    remote: remote,
                    repository: repositoryInfo.repository,
                    pushType: pushType
                )
                try await pushOperation.start()
            }
        }
    }

    func addRemote(
        fetchURLString: String,
        pushURLString: String,
        remoteName: String
    ) async {
        guard let repositoryInfo else { fatalError(.invalid) }

        Task { @MainActor in
            shouldAddRemoteBranch = false
        }

        guard let fetchURL = URL(string: fetchURLString) else { return }
        await withActivityOperation(
            title: "Adding remote..",
            successMessage: "Remote added"
        ) { [weak self] in
            guard let self else { return }
            try repositoryInfo.repository.addRemote(named: remoteName, url: fetchURL)
            if let remote = repositoryInfo.repository.remote(named: remoteName) {
                try remote.updatePushURLString(pushURLString)
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                repositoryInfo.remotes.append(Remote(name: remoteName, repository: repositoryInfo.repository.pointer)!)
                repositoryInfo.remotes.sort { $0.name! < $1.name! }
                if let index = repositoryInfo.remotes.firstIndex(where: { $0.name == remoteName }) {
                    setLastSelectedRemote(index, buttonTitle: "push")
                }
                refreshRemoteSubject?.send()
            }
        }
    }

    func commitAndPush(remote: Remote?) async {
        await tryCommitAndPush(remote: remote, pushType: .normal)
    }

    func commitAndForcePushWithLease(remote: Remote?) async {
        await tryCommitAndPush(remote: remote, pushType: .forceWithLease)
    }

    func tryCommitAndPush(remote: Remote?, pushType: Repository.PushType) async {
        if let remote {
            await actuallyCommitAndPush(remote: remote, pushType: pushType)
        } else {
            Task { @MainActor in
                addRemoteTitle = "This repository doesn't have a remote, add one to push changes to the server"
                shouldAddRemoteBranch = true
            }
        }
    }

    func actuallyCommitAndPush(
        remote: Remote,
        pushType: Repository.PushType
    ) async {
        await commit()
        await push(branchName: nil, remote: remote, pushType: pushType)
    }

    func amendAndPush(remote: Remote?) async {
        await tryAmendAndPush(remote: remote, pushType: .normal)
    }

    func amendAndForcePushWithLease(remote: Remote?) async {
        await tryAmendAndPush(remote: remote, pushType: .forceWithLease)
    }

    func tryAmendAndPush(remote: Remote?, pushType: Repository.PushType) async {
        if let remote {
            await actuallyAmendAndPush(remote: remote, pushType: pushType)
        } else {
            Task { @MainActor in
                addRemoteTitle = "This repository doesn't have a remote, add one to push changes to the server"
                shouldAddRemoteBranch = true
            }
        }
    }

    func actuallyAmendAndPush(
        remote: Remote,
        pushType: Repository.PushType
    ) async {
        await amend()
        await push(branchName: nil, remote: remote, pushType: pushType)
    }

    func stash() async {
         fatalError(.unimplemented)
    }

    func popStash() async {
        fatalError(.unimplemented)
    }

    func applyStash(stash: SelectableStash) async {
        fatalError(.unimplemented)
    }

    func trackAll() async {
        guard let repositoryInfo else { fatalError(.invalid) }
        for file in unsortedUntrackedFiles.values {
            await track(flag: true, file: file, shouldRefreshStatus: false)
        }
        Task { @MainActor in
            await repositoryInfo.refreshStatus()
        }
    }

    func track(flag: Bool, file: OldNewFile, shouldRefreshStatus: Bool = true) async {
        guard let repositoryInfo, let path = file.new else { fatalError(.invalid) }
        await withActivityOperation(
            title: "Tracking \(file.new ?? file.old!)",
            successMessage: "Tracked \(file.new ?? file.old!)"
        ) {
            if flag {
                repositoryInfo.repository.stage(path: path).mustSucceed(repositoryInfo.repository.gitDir)
            } else {
                repositoryInfo.repository.unstage(path: path).mustSucceed(repositoryInfo.repository.gitDir)
            }
        }
        if shouldRefreshStatus {
            Task { @MainActor in
                await repositoryInfo.refreshStatus()
            }
        }
    }

    func commit() async {
        await commit(amend: false)
    }

    func splitAndCommit() async -> Commit {
        fatalError(.unimplemented)
    }

    func amend() async {
        await commit(amend: true)
    }

    func commit(amend: Bool) async {
        guard let repositoryInfo else { fatalError(.invalid) }
        await withActivityOperation(
            title: amend ? "Amending changes.." : "Committing changes..",
            successMessage: amend ? "Amended changes" : "Committed changes"
        ) { [weak self] in
            guard let self else { return }
            try GitCLI.execute(repositoryInfo.repository, ["restore", "--staged", "."])
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
                case .ignored, .unreadable, .unmodified, .untracked, .conflicted:
                    fatalError(.invalid)
                }
            }

            let addArguments = ["add"] + Array(filesToAdd)
            try GitCLI.execute(repositoryInfo.repository, addArguments)
            if amend {
                if commitSummary.isEmptyOrWhitespace {
                    try GitCLI.execute(repositoryInfo.repository, ["commit", "--amend", "--no-edit", "--allow-empty"])
                } else {
                    try GitCLI.execute(repositoryInfo.repository, ["commit", "--amend", "--allow-empty", "-m", commitSummary])
                }
            } else {
                try GitCLI.execute(repositoryInfo.repository, ["commit", "--allow-empty", "-m", commitSummary])
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
            try GitCLI.execute(repositoryInfo.repository, ["restore", "--staged", "."])
            Task { @MainActor [weak self] in
                guard let self else { return }
                commitSummary = ""
                currentFile = nil
            }
        }
        Task { @MainActor in
            await repositoryInfo.refreshStatus()
        }
    }

    func ignore(file: OldNewFile) async {
        guard let repositoryInfo else { fatalError(.invalid) }
        guard let path = file.new else { fatalError(.illegal) }
        await withActivityOperation(
            title: "Ignoring \(path)",
            successMessage: "\(path) is ignored"
        ) {
            try repositoryInfo.repository.ignore(path)
        }
        Task { @MainActor in
            await repositoryInfo.refreshStatus()
        }
    }

    func discard(file: OldNewFile) async {
        guard let repositoryInfo else { fatalError(.invalid) }
        await withActivityOperation(
            title: "Discarding changes for \(file.new ?? file.old!)..",
            successMessage: "Changes discarded for \(file.new ?? file.old!)"
        ) {
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
                        try GitCLI.execute(repositoryInfo.repository, ["restore", fileURL.appendingPathComponent("*").path])
                    } else {
                        try GitCLI.execute(repositoryInfo.repository, ["restore", fileURL.path])
                    }
                case .conflicted:
                    fatalError(.invalid)
                case .unreadable:
                    fatalError(.unimplemented)
                }
            }
        }
        Task { @MainActor in
            await repositoryInfo.refreshStatus()
            if file == currentFile {
                currentFile = nil
                setInitialSelection()
            }
        }
    }

    func discardAll() async {
        guard let repositoryInfo else { fatalError(.invalid) }
        await withActivityOperation(
            title: "Discarding all changes..",
            successMessage: "All changes are discarded"
        ) {
            try GitCLI.execute(repositoryInfo.repository, ["add", "."])
            try GitCLI.execute(repositoryInfo.repository, ["reset", "--hard"])
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await repositoryInfo.refreshStatus()
            currentFile = nil
        }
    }
}
