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
    var gitWatcher: GitWatcher? = nil
    var workDirWatcher: FileEventStream? = nil
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
        self.setupGitWatcher()
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
    private func setupGitWatcher() {
        let headChangeSubject = PassthroughSubject<Void, Never>()
        let indexChangeSubject = PassthroughSubject<Void, Never>()
        let reflogChangeSubject = PassthroughSubject<Void, Never>()
        let localBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let remoteBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let tagsChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let stashChangeSubject = PassthroughSubject<Void, Never>()

        self.headChangeObserver = headChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.head = Head.of(repository)
                self.onGitChange(.head(self))
                print("head changed for repository \(repository.nameOfRepo)")
            }

        self.indexChangeObserver = indexChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.status = StatusManager.shared.status(of: self.repository)
                self.onGitChange(.index(self))
                print("index changed for repository \(repository.nameOfRepo)")
            }

        self.localBranchesChangeObserver = localBranchesChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.localBranches(self))
                //                print("local branches changed for repository \(repository.nameOfRepo): \n\(changes)")
            }

        self.remoteBranchesChangeObserver = remoteBranchesChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.remoteBranches(self))
            }

        self.tagsChangeObserver = tagsChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.tags(self))
                //                print("local branches changed for repository \(repository.nameOfRepo): \n\(changes)")
            }

        self.reflogChangeObserver = reflogChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.reflog(self))
                //                print("reflog changed for repository \(repository.nameOfRepo)")
            }

        self.stashChangeObserver = stashChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .flatMap { _ in Just(()) }
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.stash(self))
                //                print("stash changed for repository \(repository.nameOfRepo)")
            }

    }
}

// MARK: WorkDir Watcher
extension RepositoryInfo {
    private func setupWorkDirWatcher() -> FileEventStream {
        let untrackedFolders = StatusManager.shared.untrackedFiles(in: self.status)
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
                //                print("paths: \(paths), count: \(paths.count)")
                guard let self else { return }
                if paths.isEmpty {
                    print("rescan workdir")
                    self.workDirWatcher = setupWorkDirWatcher()
                }
                let statusBefore: [StatusEntry] = status
                let statusAfter: [StatusEntry] = StatusManager.shared.status(of: repository)
                var changes: Set<String> = []
                for path in paths {
                    // print("---------")
                    if repository.ignores(absolutePath: path) {
                        //                         print("ignored file changed", path.droppingPrefix(repository.workDir.path))
                        continue
                    }
                    if URL(filePath: path).deletingLastPathComponent().path.hasSuffix("~") {
                        //                        print("temporary file changed", path.droppingPrefix(repository.workDir.path))
                        // temporary file
                        continue
                    }
                    let statusBeforeContains = StatusManager.shared.trackedFiles(in: statusBefore).map(\.path).contains(path)
                    let statusAfterContains = StatusManager.shared.trackedFiles(in: statusAfter).map(\.path).contains(path)

                    if !statusBeforeContains && !statusAfterContains {
                        //                         print("untracked file changed", path.droppingPrefix(repository.workDir.path))
                        continue
                    }

                    let contents = try! String(contentsOfFile: path, encoding: .utf8)
                    // does it exist in the original repo?
                    let isDeleted = !FileManager.default.fileExists(atPath: path)
                    let worktreePath = wipWorktree.worktreeRepository.workDir.appendingPathComponent(path.droppingPrefix(repository.workDir.path + "/")).path
                    if isDeleted {
                        print("file deleted", path.droppingPrefix(repository.workDir.path))
                        try! FileManager.default.removeItem(atPath: worktreePath)
                        changes.insert("Wip - \(path.droppingPrefix(repository.workDir.path + "/")) is deleted")
                    } else {
                        let destinationURL = URL(filePath: worktreePath)
                        if destinationURL.isDirectory {
                            try? FileManager.default.createDirectory(atPath: destinationURL.path, withIntermediateDirectories: true)
                        } else {
                            let hash = contents.hash
                            if fileHashes[path] == nil {
                                fileHashes[path] = hash
                                //                                 print("file read for the first time", path.droppingPrefix(repository.workDir.path))
                            } else if fileHashes[path] != hash {
                                //                                 print("file changed", path.droppingPrefix(repository.workDir.path))
                                fileHashes[path] = hash
                            } else {
                                //                                 print("file did NOT change", path.droppingPrefix(repository.workDir.path))
                                continue
                            }
                            print("file added or modified", path.droppingPrefix(repository.workDir.path + "/"))
                            try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            FileManager.default.createFile(atPath: worktreePath, contents: contents.data(using: .utf8))
                            changes.insert("Wip - \(path.droppingPrefix(repository.workDir.path + "/")) is modified")
                        }
                    }
                }
                status = statusAfter
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
    static let gitDebounce = 2
    static let workDirDebounce = 10

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.xferro.workdirwatcher"
        return "\(identifier).\(path)"
    }
}
