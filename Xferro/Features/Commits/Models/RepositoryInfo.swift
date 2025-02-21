//
//  RepoInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Combine
import Foundation
import Observation

@Observable final class RepositoryInfo: Identifiable, Equatable {
    static let commitCountLimit: Int = 10
    static func == (lhs: RepositoryInfo, rhs: RepositoryInfo) -> Bool {
        lhs.id == rhs.id
    }
    struct BranchInfo: Identifiable, Equatable {
        var id: String {
            branch.name + branch.commit.oid.description
        }
        let branch: Branch
        let commits: [SelectableCommit]
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
        let commits: [SelectableDetachedCommit]
        let repository: Repository
        let head: Head
    }

    struct DetachedCommitInfo: Identifiable, Equatable {
        var id: String {
            detachedCommit.id + commits.reduce(into: "") { result, commit in
                result += commit.id
            }
        }
        let detachedCommit: SelectableDetachedCommit
        let commits: [SelectableDetachedCommit]
        let repository: Repository
        let head: Head
    }

    let repository: Repository
    var head: Head
    var localBranchInfos: [BranchInfo]
    var remoteBranchInfos: [BranchInfo]
    var tags: [TagInfo]
    var stashes: [SelectableStash]
    var detachedTag: TagInfo?
    var detachedCommit: DetachedCommitInfo?
    var historyCommits: [SelectableHistoryCommit]
    var gitWatcher: GitWatcher?

    let queue: TaskQueue
    var workDirWatcher: FileEventStream! = nil

    var headChangeObserver: AnyCancellable?
    var indexChangeObserver: AnyCancellable?
    var reflogChangeObserver: AnyCancellable?
    var localBranchesChangeObserver: AnyCancellable?
    var remoteBranchesChangeObserver: AnyCancellable?
    var tagsChangeObserver: AnyCancellable?
    var stashChangeObserver: AnyCancellable?
    let onGitChange: (ChangeType) -> Void
    let onWorkDirChange: (RepositoryInfo, Set<String>) -> Void

    enum ChangeType {
        case head(Head, RepositoryInfo)
        case index(RepositoryInfo)
        case reflog(RepositoryInfo)
        case localBranches(RepositoryInfo)
        case remoteBranches(RepositoryInfo)
        case tags(RepositoryInfo)
        case stash(RepositoryInfo)
    }

    init(
        repository: Repository,
        head: Head,
        localBranchInfos: [BranchInfo],
        remoteBranchInfos: [BranchInfo],
        tags: [TagInfo],
        stashes: [SelectableStash],
        detachedTag: TagInfo?,
        detachedCommit: DetachedCommitInfo?,
        historyCommits: [SelectableHistoryCommit],
        onGitChange: @escaping (ChangeType) -> Void,
        onWorkDirChange: @escaping (RepositoryInfo, Set<String>) -> Void
    ) {
        self.repository = repository
        self.head = head
        self.localBranchInfos = localBranchInfos
        self.remoteBranchInfos = remoteBranchInfos
        self.tags = tags
        self.stashes = stashes
        self.detachedTag = detachedTag
        self.detachedCommit = detachedCommit
        self.historyCommits = historyCommits
        self.onGitChange = onGitChange
        self.onWorkDirChange = onWorkDirChange
        self.queue = TaskQueue(id: Self.taskQueueID(path: repository.workDir.path))

        let headChangeSubject = PassthroughSubject<Void, Never>()
        let indexChangeSubject = PassthroughSubject<Void, Never>()
        let reflogChangeSubject = PassthroughSubject<Void, Never>()
        let localBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let remoteBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let tagsChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let stashChangeSubject = PassthroughSubject<Void, Never>()

        self.headChangeObserver = headChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.head = Head.of(repository)
                self.onGitChange(.head(self.head, self))
                print("head changed for repository \(repository.nameOfRepo)")
            }

        self.indexChangeObserver = indexChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.index(self))
                print("index changed for repository \(repository.nameOfRepo)")
            }

        self.localBranchesChangeObserver = localBranchesChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] changes in
                guard let self else { return }
                self.onGitChange(.localBranches(self))
                print("local branches changed for repository \(repository.nameOfRepo): \n\(changes)")
            }

        self.remoteBranchesChangeObserver = remoteBranchesChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] changes in
                guard let self else { return }
                self.onGitChange(.remoteBranches(self))
                print("local branches changed for repository \(repository.nameOfRepo): \n\(changes)")
            }

        self.tagsChangeObserver = tagsChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] changes in
                guard let self else { return }
                self.onGitChange(.tags(self))
                print("local branches changed for repository \(repository.nameOfRepo): \n\(changes)")
            }

        self.reflogChangeObserver = reflogChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.reflog(self))
                print("reflog changed for repository \(repository.nameOfRepo)")
            }

        self.stashChangeObserver = stashChangeSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                self.onGitChange(.stash(self))
                print("stash changed for repository \(repository.nameOfRepo)")
            }

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

        let workDirWatcher = FileEventStream(
            path: repository.workDir.path,
            excludePaths: [repository.gitDir.path],
            queue: self.queue.queue,
            latency: 1.0
        ) { [weak self] paths in
            guard let self else { return }
            let nonIgnoredPaths = Set(paths
                .filter {
                    !repository.ignores(absolutePath: $0)
                })
            if nonIgnoredPaths.isEmpty { return }
            print("paths changed at workdir \(repository.workDir):\n \(nonIgnoredPaths)")
            self.onWorkDirChange(self, nonIgnoredPaths)
        }

        guard let workDirWatcher else {
            fatalError(.unexpected)
        }
        self.workDirWatcher = workDirWatcher
    }

    deinit {
        headChangeObserver?.cancel()
        indexChangeObserver?.cancel()
        localBranchesChangeObserver?.cancel()
        remoteBranchesChangeObserver?.cancel()
        tagsChangeObserver?.cancel()
        reflogChangeObserver?.cancel()
        stashChangeObserver?.cancel()
    }

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.xferro.workdirwatcher"

        return "\(identifier).\(path)"
    }
}

extension CommitsViewModel {
    func getRepositoryInfo(_ repository: Repository) async -> RepositoryInfo {
        let head = Head.of(repository)

        let newRepositoryInfo: RepositoryInfo = RepositoryInfo(
            repository: repository,
            head: head,
            localBranchInfos: localBranchInfos(of: repository, head: head),
            remoteBranchInfos: remoteBranchInfos(of: repository, head: head),
            tags: tags(of: repository, head: head),
            stashes: stashes(of: repository),
            detachedTag: detachedTag(of: repository, head: head),
            detachedCommit: detachedCommit(of: repository, head: head),
            historyCommits: historyCommits(of: repository)) { [weak self] type in
                guard let self else { return }
                Task {
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        switch type {
                        case .head(let newHead, let repositoryInfo):
                            if let currentSelectedItem {
                                if case .regular(let item) = currentSelectedItem.selectedItemType {
                                    if case .status(let selectableStatus) = item {
                                        if selectableStatus.repository.gitDir.path == repositoryInfo.repository.gitDir.path {
                                            let selectedItem = SelectedItem(selectedItemType: .regular(.status(selectableStatus)))
                                            self.setCurrentSelectedItem(itemAndHead: (selectedItem, newHead))
                                        }
                                    }
                                }
                            }
                            repositoryInfo.detachedCommit = self.detachedCommit(of: repositoryInfo.repository, head: newHead)
                            repositoryInfo.detachedTag = self.detachedTag(of: repositoryInfo.repository, head: newHead)
                            repositoryInfo.historyCommits = self.historyCommits(of: repositoryInfo.repository)
                        case .index:
                            self.updateDetailInfo()
                        case .localBranches(let repositoryInfo):
                            repositoryInfo.localBranchInfos = self.localBranchInfos(of: repositoryInfo.repository, head: head)
                        case .remoteBranches(let repositoryInfo):
                            repositoryInfo.remoteBranchInfos = self.remoteBranchInfos(of: repositoryInfo.repository, head: head)
                        case .tags(let repositoryInfo):
                            repositoryInfo.tags = self.tags(of: repositoryInfo.repository, head: head)
                        case .reflog:
                            #warning("reflog not implemented")
                            break
                        case .stash(let repositoryInfo):
                            repositoryInfo.stashes = self.stashes(of: repositoryInfo.repository)
                        }
                    }
                }
            } onWorkDirChange: { repositoryInfo, paths in
                let head = repositoryInfo.head
            #warning("delete the line below, handle deletion and addition of files by adding wip commits and updating the detail info")
                self.updateDetailInfo()
                for path in paths {
                    if path == repositoryInfo.repository.workDir.path +/ ".gitignore" {
                        self.updateDetailInfo()
                        print("gitignore changed")
                    }
                }
            }
        return newRepositoryInfo
    }
    private func detachedAncestorCommitsOf(oid: OID, in repository: Repository, count: Int = RepositoryInfo.commitCountLimit) -> [SelectableDetachedCommit] {
        var commits: [SelectableDetachedCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableDetachedCommit(repository: repository, commit: commit))
            counter += 1
        }
        return commits
    }
    private func stashes(of repository: Repository) -> [SelectableStash] {
        var stashes = [SelectableStash]()

        try? repository.stashes().get().forEach { stash in
            stashes.append(SelectableStash(repository: repository, stash: stash))
        }
        return stashes
    }
    private func remoteBranchInfos(of repository: Repository, head: Head) -> [RepositoryInfo.BranchInfo] {
        repository.remoteBranches().mustSucceed().map {
            RepositoryInfo.BranchInfo(branch: $0, commits: [], repository: repository, head: head)
        }
    }
    private func localBranchInfos(of repository: Repository, head: Head) -> [RepositoryInfo.BranchInfo] {
        localBranches(of: repository, head: head)
            .map { [weak self] branch in
                guard let self else { return .init(branch: branch, commits: [], repository: repository, head: head) }
                let commits = commits(of: branch, in: repository)
                return RepositoryInfo.BranchInfo(branch: branch, commits: commits, repository: repository, head: head)
        }
    }
    private func localBranches(of repository: Repository, head: Head) -> [Branch] {
        var branches: [Branch] = []
        let branchIterator = BranchIterator(repo: repository, type: .local)

        while let branch = try? branchIterator.next()?.get() {
            if branch.name.hasPrefix(WipWorktree.wipBranchesPrefix) { continue }
            if isCurrentBranch(branch, head: head, in: repository) {
                branches.insert(branch, at: 0)
            } else {
                branches.append(branch)
            }
        }
        return branches
    }
    private func detachedTag(of repository: Repository, head: Head) -> RepositoryInfo.TagInfo? {
        switch head {
        case .branch:
            return nil
        case .tag(let tagReference):
            let detachedTag = SelectableDetachedTag(repository: repository, tag: tagReference)
            let commits = detachedAncestorCommitsOf(oid: detachedTag.oid, in: repository)
            return RepositoryInfo.TagInfo(tag: detachedTag, commits: commits, repository: repository, head: head)
        case .reference(let reference):
            if let tag = try? repository.tag(reference.oid).get() {
                let detachedTag = SelectableDetachedTag(repository: repository, tag: TagReference.annotated(tag.name, tag))
                let commits = detachedAncestorCommitsOf(oid: detachedTag.oid, in: repository)
                return RepositoryInfo.TagInfo(tag: detachedTag, commits: commits, repository: repository, head: head)
            } else {
                return nil
            }
        }
    }
    private func detachedCommit(of repository: Repository, head: Head) -> RepositoryInfo.DetachedCommitInfo? {
        switch head {
        case .branch, .tag:
            return nil
        case .reference(let reference):
            if let commit = try? repository.commit(reference.oid).get() {
                let detachedCommit = SelectableDetachedCommit(repository: repository, commit: commit)
                let commits = detachedAncestorCommitsOf(oid: reference.oid, in: repository)
                return RepositoryInfo.DetachedCommitInfo(detachedCommit: detachedCommit, commits: commits, repository: repository, head: head)
            } else {
                return nil
            }
        }
    }
    private func tags(of repository: Repository, head: Head) -> [RepositoryInfo.TagInfo] {
        var tags: [RepositoryInfo.TagInfo] = []

        try? repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
                let selectableTag = SelectableDetachedTag(repository: repository, tag: tag)
                let commits = detachedAncestorCommitsOf(oid: tag.oid, in: repository)
                tags.append(RepositoryInfo.TagInfo(tag: selectableTag, commits: commits, repository: repository, head: head))
            }
        return tags
    }
    private func commits(of branch: Branch, in repository: Repository, count: Int = RepositoryInfo.commitCountLimit) -> [SelectableCommit] {
        var commits: [SelectableCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: branch.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableCommit(repository: repository, branch: branch, commit: commit))
            counter += 1
        }
        return commits
    }

    #warning("history not implemented")
    private func historyCommits(of repository: Repository) -> [SelectableHistoryCommit] {
        []
    }
}
