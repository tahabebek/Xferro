//
//  RepositoryInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Combine
import Foundation
import Observation

@Observable final class RepositoryInfo: Identifiable, Equatable {
    static let commitCountLimit: Int = 10
    #warning("check if git and workdir debounces are in sync, maybe do not use status if there is a risk of race condition")
    static let gitDebounce = 2
    static let workDirDebounce = 10
    static func == (lhs: RepositoryInfo, rhs: RepositoryInfo) -> Bool {
        lhs.id == rhs.id
    }
    struct BranchInfo: Identifiable, Equatable {
        var id: String {
            branch.name + branch.commit.oid.description
        }
        let branch: Branch
        var commits: [SelectableCommit] = []
        let repository: Repository
        let head: Head
    }

    struct WipBranchInfo: Identifiable, Equatable {
        var id: String {
            branch.name + branch.commit.oid.description
        }
        let branch: Branch
        var commits: [SelectableWipCommit] = []
        let repository: Repository
        let head: Head
    }

    struct TagInfo: Identifiable, Equatable {
        var id: String {
            tag.id + commits.reduce(into: "") { result, commit in
                result += commit.id
            }
        }
        let tag: SelectableDetachedTag
        var commits: [SelectableDetachedCommit] = []
        let repository: Repository
        let head: Head
    }

    struct DetachedCommitInfo: Identifiable, Equatable {
        var id: String {
            detachedCommit.id + commits.reduce(into: "") { result, commit in
                result += commit.id
            }
        }
        var detachedCommit: SelectableDetachedCommit!
        var commits: [SelectableDetachedCommit] = []
        let repository: Repository
        let head: Head
    }

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

    enum ChangeType {
        case head(RepositoryInfo)
        case index(RepositoryInfo)
        case reflog(RepositoryInfo)
        case localBranches(RepositoryInfo)
        case remoteBranches(RepositoryInfo)
        case tags(RepositoryInfo)
        case stash(RepositoryInfo)
    }

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

        self.workDirWatcher = getWorkDirWatcher()

        self.gitWatcher = GitWatcher(
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

    private func getWorkDirWatcher() -> FileEventStream {
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
                    self.workDirWatcher = getWorkDirWatcher()
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

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.xferro.workdirwatcher"
        return "\(identifier).\(path)"
    }
}

extension CommitsViewModel {
    func getRepositoryInfo(_ repository: Repository) async -> RepositoryInfo {
        let newRepositoryInfo: RepositoryInfo = RepositoryInfo(
            repository: repository
        ) { [weak self] type in
            guard let self else { return }
            Task {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    switch type {
                    case .head(let repositoryInfo):
                        if let currentSelectedItem {
                            if case .regular(let item) = currentSelectedItem.selectedItemType {
                                if case .status(let selectableStatus) = item {
                                    if selectableStatus.repository.gitDir.path == repositoryInfo.repository.gitDir.path {
                                        let selectedItem = SelectedItem(selectedItemType: .regular(.status(selectableStatus)))
                                        self.setCurrentSelectedItem(selectedItem)
                                    }
                                }
                            }
                        }
                        repositoryInfo.detachedCommit = self.detachedCommit(of: repositoryInfo)
                        repositoryInfo.detachedTag = self.detachedTag(of: repositoryInfo)
                        repositoryInfo.historyCommits = self.historyCommits(of: repositoryInfo)
                    case .index:
                        self.updateDetailInfoAndPeekInfo()
                    case .localBranches(let repositoryInfo):
                        repositoryInfo.localBranchInfos = self.localBranchInfos(of: repositoryInfo)
                    case .remoteBranches(let repositoryInfo):
                        repositoryInfo.remoteBranchInfos = self.remoteBranchInfos(of: repositoryInfo)
                    case .tags(let repositoryInfo):
                        repositoryInfo.tags = self.tags(of: repositoryInfo)
                    case .reflog:
#warning("reflog not implemented")
                        break
                    case .stash(let repositoryInfo):
                        repositoryInfo.stashes = self.stashes(of: repositoryInfo)
                    }
                }
            }
        } onWorkDirChange: { [weak self] repositoryInfo, summary in
            guard let self else { return }
            guard autoCommitEnabled else { return }
            addWipCommit(repositoryInfo: repositoryInfo, summary: summary)
        }
        let (localBranches, remoteBranches, wipBranches) = branchInfos(of: newRepositoryInfo)
        newRepositoryInfo.localBranchInfos = localBranches
        newRepositoryInfo.remoteBranchInfos = remoteBranches
        newRepositoryInfo.wipBranchInfos = wipBranches
        newRepositoryInfo.tags = tags(of: newRepositoryInfo)
        newRepositoryInfo.stashes = stashes(of: newRepositoryInfo)
        newRepositoryInfo.detachedTag = detachedTag(of: newRepositoryInfo)
        newRepositoryInfo.detachedCommit = detachedCommit(of: newRepositoryInfo)
        newRepositoryInfo.historyCommits = historyCommits(of: newRepositoryInfo)
        newRepositoryInfo.status = StatusManager.shared.status(of: newRepositoryInfo.repository)
        return newRepositoryInfo
    }
    private func detachedAncestorCommitsOf(
        oid: OID,
        in repositoryInfo: RepositoryInfo,
        count: Int = RepositoryInfo.commitCountLimit) -> [SelectableDetachedCommit]
    {
        var commits: [SelectableDetachedCommit] = []

        let commitIterator = CommitIterator(repo: repositoryInfo.repository, root: oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableDetachedCommit(repositoryInfo: repositoryInfo, commit: commit))
            counter += 1
        }
        return commits
    }
    private func stashes(of repositoryInfo: RepositoryInfo) -> [SelectableStash] {
        var stashes = [SelectableStash]()

        try? repositoryInfo.repository.stashes().get().forEach { stash in
            stashes.append(SelectableStash(repositoryInfo: repositoryInfo, stash: stash))
        }
        return stashes
    }

    private func branchInfos(of repositoryInfo: RepositoryInfo) ->
    (local: [RepositoryInfo.BranchInfo], remote: [RepositoryInfo.BranchInfo], wip: [RepositoryInfo.WipBranchInfo]) {
        let (localBranches, remoteBranches, wipBranches) = allBranches(of: repositoryInfo)
        let local = localBranches
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        let remote = remoteBranches
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        let wip = wipBranches
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.WipBranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = wipCommits(of: branch, in: repositoryInfo)
                return RepositoryInfo.WipBranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
        return (local, remote, wip)
    }

    private func allBranches(of repositoryInfo: RepositoryInfo) -> (local: [Branch], remote: [Branch], wip: [Branch]) {
        var localBranches: [Branch] = []
        var remoteBranches: [Branch] = []
        var wipBranches: [Branch] = []
        let branchIterator = BranchIterator(repo: repositoryInfo.repository, type: .all)

        while let branch = try? branchIterator.next()?.get() {
            if branch.isWip {
                wipBranches.append(branch)
            } else if branch.isLocal {
                if isCurrentBranch(branch, head: repositoryInfo.head) {
                    localBranches.insert(branch, at: 0)
                } else {
                    localBranches.append(branch)
                }
            } else if branch.isRemote {
                remoteBranches.append(branch)
            } else {
                fatalError(.illegal)
            }
        }
        return (localBranches, remoteBranches, wipBranches)
    }

    private func localBranchInfos(of repositoryInfo: RepositoryInfo) -> [RepositoryInfo.BranchInfo] {
        localBranches(of: repositoryInfo)
            .filter {
                !$0.isWip
            }
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
    }

    private func localBranches(of repositoryInfo: RepositoryInfo) -> [Branch] {
        var branches: [Branch] = []
        let branchIterator = BranchIterator(repo: repositoryInfo.repository, type: .local)

        while let branch = try? branchIterator.next()?.get() {
            if isCurrentBranch(branch, head: repositoryInfo.head) {
                branches.insert(branch, at: 0)
            } else {
                branches.append(branch)
            }
        }
        return branches
    }

    private func remoteBranchInfos(of repositoryInfo: RepositoryInfo) -> [RepositoryInfo.BranchInfo] {
        repositoryInfo.repository.remoteBranches().mustSucceed()
            .map { [weak self] branch in
                guard let self else { return RepositoryInfo.BranchInfo(branch: branch, commits: [], repository: repositoryInfo.repository, head: repositoryInfo.head) }
                let commits = commits(of: branch, in: repositoryInfo)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            }
    }

    private func detachedTag(of repositoryInfo: RepositoryInfo) -> RepositoryInfo.TagInfo? {
        switch repositoryInfo.head {
        case .branch:
            return nil
        case .tag(let tagReference):
            let detachedTag = SelectableDetachedTag(repositoryInfo: repositoryInfo, tag: tagReference)
            let commits = detachedAncestorCommitsOf(oid: detachedTag.oid, in: repositoryInfo)
            return RepositoryInfo.TagInfo(tag: detachedTag, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
        case .reference(let reference):
            if let tag = try? repositoryInfo.repository.tag(reference.oid).get() {
                let detachedTag = SelectableDetachedTag(repositoryInfo: repositoryInfo, tag: TagReference.annotated(tag.name, tag))
                let commits = detachedAncestorCommitsOf(oid: detachedTag.oid, in: repositoryInfo)
                return RepositoryInfo.TagInfo(tag: detachedTag, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            } else {
                return nil
            }
        }
    }
    private func detachedCommit(of repositoryInfo: RepositoryInfo) -> RepositoryInfo.DetachedCommitInfo? {
        switch repositoryInfo.head {
        case .branch, .tag:
            return nil
        case .reference(let reference):
            if let commit = try? repositoryInfo.repository.commit(reference.oid).get() {
                let detachedCommit = SelectableDetachedCommit(repositoryInfo: repositoryInfo, commit: commit)
                let commits = detachedAncestorCommitsOf(oid: reference.oid, in: repositoryInfo)
                return RepositoryInfo.DetachedCommitInfo(detachedCommit: detachedCommit, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head)
            } else {
                return nil
            }
        }
    }
    private func tags(of repositoryInfo: RepositoryInfo) -> [RepositoryInfo.TagInfo] {
        var tags: [RepositoryInfo.TagInfo] = []

        try? repositoryInfo.repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
                let selectableTag = SelectableDetachedTag(repositoryInfo: repositoryInfo, tag: tag)
                let commits = detachedAncestorCommitsOf(oid: tag.oid, in: repositoryInfo)
                tags.append(RepositoryInfo.TagInfo(tag: selectableTag, commits: commits, repository: repositoryInfo.repository, head: repositoryInfo.head))
            }
        return tags
    }
    private func commits(
        of branch: Branch,
        in repositoryInfo: RepositoryInfo,
        count: Int = RepositoryInfo.commitCountLimit) -> [SelectableCommit] {
            var commits: [SelectableCommit] = []

            let commitIterator = CommitIterator(repo: repositoryInfo.repository, root: branch.oid.oid)
            var counter = 0
            while counter < count, let commit = try? commitIterator.next()?.get() {
                commits.append(SelectableCommit(repositoryInfo: repositoryInfo, branch: branch, commit: commit))
                counter += 1
            }
            return commits
        }
    private func wipCommits(
        of branch: Branch,
        in repositoryInfo: RepositoryInfo,
        count: Int = RepositoryInfo.commitCountLimit) -> [SelectableWipCommit] {
            var commits: [SelectableWipCommit] = []

            let commitIterator = CommitIterator(repo: repositoryInfo.repository, root: branch.oid.oid)
            var counter = 0
            while counter < count, let commit = try? commitIterator.next()?.get() {
                commits.append(SelectableWipCommit(repositoryInfo: repositoryInfo, branch: branch, commit: commit))
                counter += 1
            }
            return commits
        }

#warning("history not implemented")
    private func historyCommits(of repositoryInfo: RepositoryInfo) -> [SelectableHistoryCommit] {
        []
    }
}
