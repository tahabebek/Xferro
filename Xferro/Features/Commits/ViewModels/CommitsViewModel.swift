//aaa
//  CommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Combine
import Foundation
import Observation
import OrderedCollections

@Observable class CommitsViewModel {
    struct CurrentWipCommits {
        let commits: [SelectableWipCommit]
        let item: SelectedItem
    }

    var autoCommitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCommitEnabled, forKey: "autoCommitEnabled")
        }
    }

    // use the func setCurrentSelectedItem to set currentSelectedItem
    var currentSelectedItem: SelectedItem?

    func setCurrentSelectedItem(_ selectedItem: SelectedItem?) {
        user.lastSelectedRepositoryPath = selectedItem?.repository.gitDir.path
        if let selectedItem {
            getWipCommits(selectedItem: selectedItem)
        } else {
            getWipCommits(selectedItem: nil)
        }
        currentSelectedItem = selectedItem
        updateDetailInfoAndPeekInfo()
    }

    var currentWipCommits: CurrentWipCommits?
    var currentDetailInfo: DetailInfo?
    var currentPeekInfo: PeekInfo?
    let detailsViewModel = DetailsViewModel(detailInfo: DetailInfo(type: .empty))
    let peekViewModel = PeekViewModel(peekInfo: PeekInfo(title: ""))

    var currentRepositoryInfos: OrderedDictionary<String, RepositoryInfo> = [:]
    private let userDidSelectFolder: (URL) -> Void
    private let user: User
    let wipCommitLock = NSRecursiveLock()

    init(
        repositories: [Repository],
        user: User,
        userDidSelectFolder: @escaping (URL) -> Void
    ) {
        if UserDefaults.standard.object(forKey: "autoCommitEnabled") == nil {
            self.autoCommitEnabled = true
        } else {
            self.autoCommitEnabled = UserDefaults.standard.bool(forKey: "autoCommitEnabled")
        }
        self.userDidSelectFolder = userDidSelectFolder
        self.user = user

        Task {
            for repository in repositories {
                await addRepository(repository)
            }
            await MainActor.run {
                setupInitialCurrentSelectedItem()
            }
        }
    }

    func addRepository(_ repository: Repository) async {
        await updateRepositoryInfo(repository)
    }

    private func updateRepositoryInfo(_ repository: Repository) async {
        let repositoryInfo = await getRepositoryInfo(repository)
        await MainActor.run {
            currentRepositoryInfos[kRepositoryInfo(repository)] = repositoryInfo
        }
    }

    func updateDetailInfoAndPeekInfo() {
        Task {
            await MainActor.run {
                guard let currentSelectedItem else {
                    currentDetailInfo = nil
                    detailsViewModel.detailInfo = DetailInfo(type: .empty)

                    currentPeekInfo = nil
                    peekViewModel.peekInfo = PeekInfo(title: "")
                    return
                }
                switch currentSelectedItem.selectedItemType {
                case .regular(let type):
                    switch type {
                    case .stash(let stash):
                        currentDetailInfo = DetailInfo(type: .stash(stash))
                        currentPeekInfo = PeekInfo(title: "stash \(stash.oid.debugOID)")
                    case .status(let status):
                        currentDetailInfo = DetailInfo(type: .status(status))
                        currentPeekInfo = PeekInfo(title: "status \(status.oid.debugOID)")
                    case .commit(let commit):
                        currentDetailInfo = DetailInfo(type: .commit(commit))
                        currentPeekInfo = PeekInfo(title: "commit \(commit.oid.debugOID)")
                    case .detachedCommit(let commit):
                        currentDetailInfo = DetailInfo(type: .detachedCommit(commit))
                        currentPeekInfo = PeekInfo(title: "commit \(commit.oid.debugOID)")
                    case .detachedTag(let tag):
                        currentDetailInfo = DetailInfo(type: .detachedTag(tag))
                        currentPeekInfo = PeekInfo(title: "tag \(tag.oid.debugOID)")
                    case .tag(let tag):
                        currentDetailInfo = DetailInfo(type: .tag(tag))
                        currentPeekInfo = PeekInfo(title: "tag \(tag.oid.debugOID)")
                    case .historyCommit(let commit):
                        currentDetailInfo = DetailInfo(type: .historyCommit(commit))
                        currentPeekInfo = PeekInfo(title: "commit \(commit.oid.debugOID)")
                    }
                case .wip(let wip):
                    switch wip {
                    case .wipCommit(let commit):
                        guard let worktree = WipWorktree.get(for: commit.repository) else {
                            fatalError(.impossible)
                        }
                        currentDetailInfo = DetailInfo(type: .wipCommit(commit, worktree))
                        currentPeekInfo = PeekInfo(title: "commit \(commit.oid.debugOID)")
                    }
                }
                detailsViewModel.detailInfo = currentDetailInfo!
                peekViewModel.peekInfo = currentPeekInfo!
            }
        }
    }

    private func setupInitialCurrentSelectedItem() {
        Task {
            await MainActor.run {
                guard currentSelectedItem == nil else { return }
                if !currentRepositoryInfos.isEmpty {
                    var repositoryInfo: RepositoryInfo?
                    if let lastSelectedRepositoryPath = user.lastSelectedRepositoryPath {
                        for (_, info) in currentRepositoryInfos {
                            if info.repository.gitDir.path == lastSelectedRepositoryPath {
                                repositoryInfo = info
                                break
                            }
                        }
                    }
                    if repositoryInfo == nil {
                        repositoryInfo = currentRepositoryInfos.values[0]
                    }

                    if let repositoryInfo {
                        let selectedItem = SelectedItem(
                            selectedItemType: .regular(
                                .status(SelectableStatus(repositoryInfo: repositoryInfo))
                            )
                        )
                        setCurrentSelectedItem(selectedItem)
                    }
                }
            }
        }
    }

    func isSelected(item: any SelectableItem) -> Bool {
        switch item {
        case let status as SelectableStatus:
            if case .regular(.status(let currentStatus)) = currentSelectedItem?.selectedItemType {
                return status == currentStatus
            } else {
                return false
            }
        case let commit as SelectableCommit:
            if case .regular(.commit(let currentCommit)) = currentSelectedItem?.selectedItemType  {
                return commit == currentCommit
            } else {
                return false
            }
        case let wipCommit as SelectableWipCommit:
            if case .wip(.wipCommit(let currentWipCommit)) = currentSelectedItem?.selectedItemType  {
                return wipCommit == currentWipCommit
            } else {
                return false
            }
        case let historyCommit as SelectableHistoryCommit:
            if case .regular(.historyCommit(let currentHistoryCommit)) = currentSelectedItem?.selectedItemType  {
                return historyCommit == currentHistoryCommit
            } else {
                return false
            }
        case let detachedCommit as SelectableDetachedCommit:
            if case .regular(.detachedCommit(let currentDetachedCommit)) = currentSelectedItem?.selectedItemType  {
                return detachedCommit == currentDetachedCommit
            } else {
                return false
            }
        case let detachedTag as SelectableDetachedTag:
            if case .regular(.detachedTag(let currentDetachedTag)) = currentSelectedItem?.selectedItemType  {
                return detachedTag == currentDetachedTag
            } else {
                return false
            }
        case let tag as SelectableTag:
            if case .regular(.tag(let currentTag)) = currentSelectedItem?.selectedItemType  {
                return tag == currentTag
            } else {
                return false
            }
        case let stash as SelectableStash:
            if case .regular(.stash(let currentStash)) = currentSelectedItem?.selectedItemType  {
                return stash == currentStash
            } else {
                return false
            }
        default:
            fatalError()
        }
    }

    func isCurrentBranch(_ branch: Branch, head: Head) -> Bool {
        switch head {
        case .branch(let headBranch, _):
            if branch == headBranch {
                return true
            }
        default:
            break
        }
        return false
    }

    // MARK: User actions
    func userTapped(item: any SelectableItem) {
        Task {
            await MainActor.run {
                let selectedItem: SelectedItem
                switch item {
                case let status as SelectableStatus:
                    selectedItem = .init(selectedItemType: .regular(.status(status)))
                case let commit as SelectableCommit:
                    selectedItem = .init(selectedItemType: .regular(.commit(commit)))
                case let wipCommit as SelectableWipCommit:
                    selectedItem = .init(selectedItemType: .wip(.wipCommit(wipCommit)))
                case let historyCommit as SelectableHistoryCommit:
                    selectedItem = .init(selectedItemType: .regular(.historyCommit(historyCommit)))
                case let detachedCommit as SelectableDetachedCommit:
                    selectedItem = .init(selectedItemType: .regular(.detachedCommit(detachedCommit)))
                case let detachedTag as SelectableDetachedTag:
                    selectedItem = .init(selectedItemType: .regular(.detachedTag(detachedTag)))
                case let tag as SelectableTag:
                    selectedItem = .init(selectedItemType: .regular(.tag(tag)))
                case let stash as SelectableStash:
                    selectedItem = .init(selectedItemType: .regular(.stash(stash)))
                default:
                    fatalError()
                }
                setCurrentSelectedItem(selectedItem)
            }
        }
    }

    func deleteBranchTapped(repository: Repository, branchName: String) {
        repository.deleteBranch(branchName).mustSucceed()
    }

    func usedDidSelectFolder(_ folder: URL) {
        let gotAccess = folder.startAccessingSecurityScopedResource()
        if !gotAccess { return }
        do {
            let bookmarkData = try folder.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            UserDefaults.standard.set(bookmarkData, forKey: folder.path)
        } catch {
            fatalError("Failed to create bookmark: \(error)")
        }

        folder.stopAccessingSecurityScopedResource()
        userDidSelectFolder(folder)
    }

    func deleteRepositoryButtonTapped(_ repository: Repository) {
        guard currentRepositoryInfos[kRepositoryInfo(repository)] != nil else {
            fatalError(.unexpected)
        }
        Task {
            await MainActor.run {
                currentRepositoryInfos.removeValue(forKey: kRepositoryInfo(repository))
                if let currentSelectedItem {
                    if currentSelectedItem.repository.gitDir.path == repository.gitDir.path {
                        setCurrentSelectedItem(nil)
                    }
                }
                user.removeProject(repository.gitDir.deletingLastPathComponent())
            }
        }
    }

    func stageOrUnstageButtonTapped(stage: Bool, repository: Repository, deltaInfos: [DeltaInfo]) {
        for deltaInfo in deltaInfos {
            switch deltaInfo.delta.status {
            case .unmodified:
                fatalError(.unexpected)
            case .added:
                guard let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .deleted:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                }
            case .modified:
                guard let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
//                    print("stage \(newFilePath)")
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
//                    print("unstage \(newFilePath)")
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .renamed:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path,
                      let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .copied:
                guard let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .ignored:
                fatalError(.unimplemented)
            case .untracked:
                guard let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .typeChange:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path,
                      let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.unexpected)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }
    }

    func stageAllButtonTapped(repository: Repository) {
        repository.stage(path: ".").mustSucceed()
    }

    @discardableResult
    func commitTapped(repository: Repository, message: String) -> Commit {
        repository.commit(message: message).mustSucceed()
    }

    func amendTapped(repository: Repository, message: String?) {
        let headCommit: Commit = repository.commit().mustSucceed()
        var newMessage = message
        if newMessage == nil || (newMessage ?? "").isEmptyOrWhitespace {
            newMessage = headCommit.summary
        }

        guard let newMessage, !newMessage.isEmptyOrWhitespace else {
            fatalError(.unsupported)
        }
        repository.amend(message: newMessage).mustSucceed()
    }

    func ignoreButtonTapped(repository: Repository, deltaInfo: DeltaInfo) {
        guard let path = deltaInfo.newFilePath else {
            fatalError(.illegal)
        }
        repository.ignore(path)
    }

    func discardFileButtonTapped(repository: Repository, fileURLs: [URL]) {
        for fileURL in fileURLs {
            if fileURL.isDirectory {
                RepoManager().git(repository, ["restore", fileURL.appendingPathComponent("*").path])
            } else {
                RepoManager().git(repository, ["restore", fileURL.path])
            }
        }
    }

    // MARK: Keys
    private func kGitWatcher(_ repository: Repository) -> String {
        String("git_watch_" + repository.gitDir.path)
    }
    private func kFolderWatcher(_ repository: Repository) -> String {
        String("folder_watch_" + repository.gitDir.path)
    }
    private func kRepositoryInfo(_ repository: Repository) -> String {
        String("info_" + repository.gitDir.path())
    }
    private func kFolderObserver(_ repository: Repository) -> String {
        String("folder_observe_" + repository.gitDir.path())
    }
    private func kGitObserver(_ repository: Repository) -> String {
        String("git_observe_" + repository.gitDir.path())
    }
}
