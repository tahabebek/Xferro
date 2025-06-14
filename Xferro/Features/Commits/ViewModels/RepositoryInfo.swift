//d
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
    var remotes: [Remote] = []
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

    var onGitChange: ((ChangeType) async -> Void)?
    var onWorkDirChange: ((RepositoryInfo, String?) -> Void)?
    var onUserTapped: ((any SelectableItem) -> Void)?
    var onIsSelected: ((any SelectableItem) -> Bool)?
    var onDeleteRepositoryTapped: ((Repository) -> Void)?
    var onDeleteBranchTapped: ((String) -> Void)?
    var onIsCurrentBranch: ((Branch, Head) -> Bool)?

    var observers: Set<AnyCancellable> = []
    var refreshRemoteSubject: PassthroughSubject<Void, Never> = .init()

    var wipWorktree: WipWorktree {
        WipWorktree.worktree(for: self)
    }

    init(repository: Repository) {
        self.repository = repository
        let head = Head.of(repository)
        self.head = head
        self.queue = TaskQueue(id: Self.taskQueueID(path: repository.workDir.path))
        self.gitWatcher = self.setupGitWatcher()
        self.workDirWatcher = setupWorkDirWatcher()

        refreshRemoteSubject
            .eraseToAnyPublisher()
            .sink { [weak self] in
                guard let self else { return }
                remotes = repository.allRemotes().mustSucceed(repository.gitDir)
            }
            .store(in: &observers)
    }

    func deleteRepositoryTapped() {
        onDeleteRepositoryTapped?(repository)
    }

    func refreshStatus() async {
        status = await StatusManager.shared.status(of: self.repository)
        await onGitChange?(.index(self))
    }

    func createBranchTapped(
        branchName: String,
        baseBranchName: String,
        isRemote: Bool,
        shouldCheckout: Bool
    ) {
        Task {
            if shouldCheckout {
                if status.isNotEmpty {
                    Task { @MainActor in
                        AppDelegate.showErrorMessage(
                            error: RepoError.unexpected("Cannot checkout to a different branch when there are uncommitted changes")
                        )
                    }
                    return
                }
            }
            
            await withActivityOperation(
                title: isRemote ? "Creating remote branch \(branchName) to track \(baseBranchName)"
                    : "Creating local branch \(branchName) based on \(baseBranchName)"
            ) { [weak self] in
                guard let self else { return }
                if shouldCheckout {
                    try GitCLI.execute(repository, ["checkout", "-b", branchName, baseBranchName])
                } else {
                    try GitCLI.execute(repository, ["branch", branchName, baseBranchName])
                }
            }
        }
    }

    func checkoutBranchTapped(branchName: String, isRemote: Bool) {
        Task {
            if status.isNotEmpty {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(
                        error: RepoError.unexpected("Cannot checkout to a different branch when there are uncommitted changes")
                    )
                }
                return
            }

            await withActivityOperation(
                title: isRemote ? "Checking out to remote branch \(branchName)"
                : "Checking out to local branch \(branchName)"
            ) { [weak self] in
                guard let self else { return }
                if isRemote {
                    if localBranchInfos.map(\.branch.name).contains(branchName) {
                        try GitCLI.execute(repository, ["checkout", branchName])
                    } else {
                        try GitCLI.execute(repository, ["checkout", "-b", branchName])
                    }
                } else {
                    try GitCLI.execute(repository, ["checkout", branchName])
                }

            }
        }
    }

    func deleteBranchTapped(branchName: String, isRemote: Bool) {
        Task {
            if head.name == branchName {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(
                        error: RepoError.unexpected("Cannot delete the current branch")
                    )
                }
                return
            }

            await withActivityOperation(
                title: isRemote ? "Deleting remote branch \(branchName)"
                : "Deleting local branch \(branchName)"
            ) { [weak self] in
                guard let self else { return }
                 if isRemote {
                    let remote = String(branchName.split(separator: "/").first!)
                    let branch = String(branchName.split(separator: "/").last!)
                    try GitCLI.execute(repository, ["push", "--delete", remote , branch])
                } else {
                    try GitCLI.execute(repository, ["branch", "-D", branchName])
                }
            }
        }
    }

    func createTagTapped(name: String, message: String?, remote: String, push: Bool) {
        Task {
            await withActivityOperation(title: "Creating tag \(name) on remote \(remote)") { [weak self] in
                guard let self else { return }
                var args = ["tag"]
                if let message {
                    args.append(contentsOf: ["-a", name, "-m", message])
                } else {
                    args.append(name)
                }
                try GitCLI.execute(repository, args)
                if push {
                    try GitCLI.execute(repository, ["push", remote, name])
                }
            }
        }
    }

    func mergeBranchTapped(target: String, destination: String) {
        Task {
            if head.name != destination {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(
                        error: RepoError.unexpected("You need to be on the destination branch when merging because Git's merge command integrates changes from a specified branch into your current branch.")
                    )
                }
                return
            }

            if status.isNotEmpty {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(
                        error: RepoError.unexpected("Please commit your changes or stash them before you merge.")
                    )
                }
                return
            }
            await withActivityOperation(title: "Merging branch \(target) into \(destination)") { [weak self] in
                guard let self else { return }
                do {
                    try GitCLI.execute(repository, ["merge", target])
                } catch {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await refreshStatus()
                    }
                }
            }
        }
    }

    func rebaseBranchTapped(target: String, destination: String) {
        Task {
            if head.name != destination {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(
                        error: RepoError.unexpected("You need to be on the destination branch when rebasing because Git's rebase command integrates changes from a specified branch into your current branch.")
                    )
                }
                return
            }

            if status.isNotEmpty {
                Task { @MainActor in
                    AppDelegate.showErrorMessage(
                        error: RepoError.unexpected("Please commit your changes or stash them before you rebase.")
                    )
                }
                return
            }

            await withActivityOperation(title: "Rebasing branch \(target) into \(destination)") { [weak self] in
                guard let self else { return }
                do {
                    try GitCLI.execute(repository, ["rebase", target])
                } catch {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await refreshStatus()
                    }
                }
            }
        }
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
        for observer in observers {
            observer.cancel()
        }
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
#warning("check with git, maybe do not use status if there is a risk of race conditions")
    static let workDirDebounce = 5

    static func taskQueueID(path: String) -> String {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.workdirwatcher"
        return "\(identifier).\(path)"
    }
}
