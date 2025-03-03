//
//  RepositoryViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Combine
import Foundation
import Observation

@Observable final class RepositoryViewModel: Identifiable {
    let repository: Repository
    var head: Head
    var headOID: OID { head.oid }
    var localBranchInfos: [BranchInfo] = []
    var remoteBranchInfos: [BranchInfo] = []
    var wipBranchInfos: [WipBranchInfo] = []
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
    
    var onGitChange: ((ChangeType) -> Void)?
    var onWorkDirChange: ((RepositoryViewModel, String?) -> Void)?
    var onUserTapped: ((any SelectableItem) -> Void)?
    var onIsSelected: ((any SelectableItem) -> Bool)?
    var onDeleteRepositoryTapped: ((Repository) -> Void)?
    var onDeleteBranchTapped: ((String) -> Void)?
    var onIsCurrentBranch: ((Branch, Head) -> Bool)?

    var wipWorktree: WipWorktree {
        WipWorktree.worktree(for: self)
    }

    init(repository: Repository) {
//        print("init repository view model")
        self.repository = repository
        let head = Head.of(repository)
        self.head = head
        self.status = StatusManager.shared.status(of: repository)
        self.queue = TaskQueue(id: Self.taskQueueID(path: repository.workDir.path))
        self.gitWatcher = self.setupGitWatcher()
        self.workDirWatcher = setupWorkDirWatcher()
    }

    func deleteRepositoryTapped()
    {
        onDeleteRepositoryTapped?(repository)
    }

    deinit {
//        print("deinit repository view model")
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

// MARK: Equatable
extension RepositoryViewModel: Equatable {
    static func == (lhs: RepositoryViewModel, rhs: RepositoryViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Static
extension RepositoryViewModel {
    static let commitCountLimit: Int = 10
#warning("check if git and workdir debounces are in sync, maybe do not use status if there is a risk of race condition")
    static let workDirDebounce = 5

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.xferro.workdirwatcher"
        return "\(identifier).\(path)"
    }
}
