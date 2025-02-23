//
//  RepositoryInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Combine
import Foundation
import Observation

@Observable final class RepositoryInfo: Identifiable {
    let repository: Repository
    var head: Head
    var headOID: OID { head.oid }
    var localBranchInfos: [BranchInfo] = []
    var remoteBranchInfos: [BranchInfo] = []
    var wipBranchInfos: [WipBranchInfo] = []
    var wipWorktree: WipWorktree
    var tags: [TagInfo] = []
    var stashes: [SelectableStash] = []
    var detachedTag: TagInfo? = nil
    var detachedCommit: DetachedCommitInfo? = nil
    var historyCommits: [SelectableHistoryCommit] = []
    var status: [StatusEntry] = []
    var gitWatcher: GitWatcher!
    var workDirWatcher: FileEventStream!
    var fileHashes: [String: Hash] = [:]
    let queue: TaskQueue

    var headChangeObserver: AnyCancellable?
    var indexChangeObserver: AnyCancellable?
    var reflogChangeObserver: AnyCancellable?
    var localBranchesChangeObserver: AnyCancellable?
    var remoteBranchesChangeObserver: AnyCancellable?
    var tagsChangeObserver: AnyCancellable?
    var stashChangeObserver: AnyCancellable?
    var workDirChangeObserver: AnyCancellable?
    let onGitChange: (ChangeType) -> Void
    let onWorkDirChange: (RepositoryInfo, String?) -> Void

    init(
        repository: Repository,
        onGitChange: @escaping (ChangeType) -> Void,
        onWorkDirChange: @escaping (RepositoryInfo, String?) -> Void
    ) {
        self.repository = repository
        let head = Head.of(repository)
        self.wipWorktree = WipWorktree.worktree(for: repository, headOID: head.oid)
        self.head = head
        self.onGitChange = onGitChange
        self.onWorkDirChange = onWorkDirChange
        self.status = StatusManager.shared.status(of: repository)
        self.queue = TaskQueue(id: Self.taskQueueID(path: repository.workDir.path))
        self.gitWatcher = self.setupGitWatcher()
        self.workDirWatcher = setupWorkDirWatcher()
    }

    deinit {
        headChangeObserver?.cancel()
        indexChangeObserver?.cancel()
        localBranchesChangeObserver?.cancel()
        remoteBranchesChangeObserver?.cancel()
        tagsChangeObserver?.cancel()
        reflogChangeObserver?.cancel()
        stashChangeObserver?.cancel()
        workDirChangeObserver?.cancel()
    }
}

// MARK: Git Watcher
extension RepositoryInfo {
    private func setupGitWatcher() -> GitWatcher {
        let headChangeSubject = PassthroughSubject<Void, Never>()
        let indexChangeSubject = PassthroughSubject<Void, Never>()
        let reflogChangeSubject = PassthroughSubject<Void, Never>()
        let localBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let remoteBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let tagsChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let stashChangeSubject = PassthroughSubject<Void, Never>()

        self.headChangeObserver = headChangeSubject
            .sink { [weak self] in
                guard let self else { return }
                print("head changed for repository \(repository.nameOfRepo)")
                self.head = Head.of(repository)
                self.onGitChange(.head(self))
            }

        self.indexChangeObserver = indexChangeSubject
            .sink { [weak self] in
                guard let self else { return }
                print("index changed for repository \(repository.nameOfRepo)")
                self.status = StatusManager.shared.status(of: self.repository)
                self.onGitChange(.index(self))
            }

        self.localBranchesChangeObserver = localBranchesChangeSubject
            .sink { [weak self] _ in
                guard let self else { return }
                print("local branches changed for repository \(repository.nameOfRepo)")
                self.onGitChange(.localBranches(self))
            }

        self.remoteBranchesChangeObserver = remoteBranchesChangeSubject
            .sink { [weak self] _ in
                guard let self else { return }
                print("remote branches changed for repository \(repository.nameOfRepo)")
                self.onGitChange(.remoteBranches(self))
            }

        self.tagsChangeObserver = tagsChangeSubject
            .sink { [weak self] _ in
                guard let self else { return }
                print("tags changed for repository \(repository.nameOfRepo)")
                self.onGitChange(.tags(self))
            }

        self.reflogChangeObserver = reflogChangeSubject
            .sink { [weak self] in
                guard let self else { return }
                print("reflog changed for repository \(repository.nameOfRepo)")
                self.onGitChange(.reflog(self))
            }

        self.stashChangeObserver = stashChangeSubject
            .sink { [weak self] in
                guard let self else { return }
                print("stash changed for repository \(repository.nameOfRepo)")
                self.onGitChange(.stash(self))
            }

        return GitWatcher(
            repository: repository,
            headChangePublisher: headChangeSubject,
            indexChangePublisher: indexChangeSubject,
            reflogChangePublisher: reflogChangeSubject,
            localBranchesChangePublisher: localBranchesChangeSubject,
            remoteBranchesChangePublisher: remoteBranchesChangeSubject,
            tagsChangePublisher: tagsChangeSubject,
            stashChangePublisher: stashChangeSubject
        )
    }
}

// MARK: WorkDir Watcher
extension RepositoryInfo {
    private func setupWorkDirWatcher() -> FileEventStream {
        let untrackedFolders = StatusManager.shared.untrackedPaths(in: self.status)
            .filter {
                $0.isDirectory
            }
            .map { $0.path }

        #warning("add global ignore, and exclude file")
        let gitignoreLines = repository.gitignoreLines()
        let workDirChangeSubject = PassthroughSubject<Set<String>, Never>()

        self.workDirChangeObserver = workDirChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.workDirDebounce)))
            .sink { [weak self] batchPaths in
                guard let self else { return }
                self.status = StatusManager.shared.status(of: repository)
                let paths = Set(batchPaths
                    .flatMap { batch in
                        batch.map { path in
                            if path.hasSuffix("~") {
                                String(path.dropLast())
                            } else {
                                path
                            }
                        }
                    }
                )
                if paths.isEmpty {
                    print("rescan workdir")
                    self.workDirWatcher = setupWorkDirWatcher()
                }
                var changes: Set<String> = []
                for path in paths {
                    if repository.ignores(absolutePath: path) {
                        #warning("check and implement the logic below if necessary")
                        // does the worktree have this file?
                            // yes
                                // Write .gitignore to the worktree
                                // ✅ delete from the worktree

                        continue
                    }
                    if URL(filePath: path).deletingLastPathComponent().path.hasSuffix("~") {
                        continue
                    }


                    let relativePath = path.droppingPrefix(repository.workDir.path + "/")
                    let destinationPath = wipWorktree.worktreeRepository.workDir.appendingPathComponent(relativePath).path
                    let destinationURL = URL(filePath: destinationPath)
                    let changeFileName = destinationURL.lastPathComponent

                    // is this file in staged or unstaged?
                    if StatusManager.shared.isStagedOrUnstaged(relativePath: relativePath, statusEntries: status) {
                        let isDeleted = !FileManager.default.fileExists(atPath: path)
                        if isDeleted {
                            print("file deleted", relativePath)
                            try! FileManager.default.removeItem(atPath: destinationPath)
                            changes.insert("Wip - \(changeFileName) is deleted")
                        } else {
                            if destinationURL.isDirectory {
                                try? FileManager.default.createDirectory(atPath: destinationURL.path, withIntermediateDirectories: true)
                            } else {
                                let contents = try! String(contentsOfFile: path, encoding: .utf8)
                                let hash = contents.hash
                                if fileHashes[path] == nil {
                                    fileHashes[path] = hash
                                } else if fileHashes[path] != hash {
                                    fileHashes[path] = hash
                                } else {
                                    continue
                                }
                                print("file added or modified", relativePath)
                                try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                                FileManager.default.createFile(atPath: destinationPath, contents: contents.data(using: .utf8))
                                changes.insert("Wip - \(changeFileName) is modified")
                            }
                        }
                    } else {
                        // is it in untracked?
                        if StatusManager.shared.isUntracked(relativePath: relativePath, statusEntries: status) {
                            // does the worktree have it?
                            if FileManager.default.fileExists(atPath: destinationPath) {
                                try! FileManager.default.removeItem(atPath: destinationPath)
                                print("untracked file deleted from worktree", destinationPath)
                                changes.insert("Wip - \(changeFileName) is removed")
                            } else {
                                continue
                            }
                        } else {
                            // does the original repo have it?
                            if FileManager.default.fileExists(atPath: path) {
                                let contents = try! String(contentsOfFile: path, encoding: .utf8)
                                let hash = contents.hash
                                if fileHashes[path] == nil {
                                    fileHashes[path] = hash
                                } else if fileHashes[path] != hash {
                                    fileHashes[path] = hash
                                } else {
                                    continue
                                }
                                try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                                FileManager.default.createFile(atPath: destinationPath, contents: contents.data(using: .utf8))
                                changes.insert("Wip - \(changeFileName) is modified")
                                print("file (which is not in the index) added or modified", relativePath)
                            } else {
                                if FileManager.default.fileExists(atPath: destinationPath) {
                                    try! FileManager.default.removeItem(atPath: destinationPath)
                                    changes.insert("Wip - \(changeFileName) is removed")
                                    print("untracked file deleted from worktree", destinationPath)
                                }
                            }
                        }
                    }
                }
                if changes.isNotEmpty {
                    self.onWorkDirChange(self, changes.count == 1 ? changes.first! : "Wip - \(changes.count) files are changed")
                }
            }

        return FileEventStream(
            path: repository.workDir.path,
            excludePaths: [repository.gitDir.path] + untrackedFolders,
            gitignoreLines: gitignoreLines,
            workDir: repository.workDir,
            queue: self.queue.queue,
            changePublisher: workDirChangeSubject)
    }
}

// MARK: Equatable
extension RepositoryInfo: Equatable {
    static func == (lhs: RepositoryInfo, rhs: RepositoryInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Static
extension RepositoryInfo {
    static let commitCountLimit: Int = 10
#warning("check if git and workdir debounces are in sync, maybe do not use status if there is a risk of race condition")
    static let workDirDebounce = 5

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.xferro.workdirwatcher"
        return "\(identifier).\(path)"
    }
}
