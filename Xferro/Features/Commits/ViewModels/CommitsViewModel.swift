//
//  CommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Combine
import Foundation
import Observation
import OrderedCollections

@Observable final class CommitsViewModel {
    var autoCommitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCommitEnabled, forKey: "autoCommitEnabled")
        }
    }
    
    // use the func setCurrentSelectedItem to set currentSelectedItem
    private(set) var currentSelectedItem: SelectedItem?

    func setCurrentSelectedItem(_ selectedItem: SelectedItem?) {
        guard currentSelectedItem != selectedItem else { return }
        user.lastSelectedRepositoryPath = selectedItem?.repository.gitDir.path
        if let selectedItem {
            getWipCommits(selectedItem: selectedItem)
        } else {
            getWipCommits(selectedItem: nil)
        }
        updateDetailInfo(selectedItem: selectedItem)
        updateDeltaInfo(selectedItem: selectedItem)
        currentSelectedItem = selectedItem
    }
    
    var currentWipCommits: WipCommits?
    var currentDetailInfo: DetailInfo?
    var currentDeltaInfo: DeltaInfo?
    private(set) var currentDeltaInfos = Dictionary<OID, DeltaInfo>()

    func setCurrentDeltaInfo(oid: OID, deltaInfo: DeltaInfo) {
        currentDeltaInfos[oid] = deltaInfo
        updateDeltaInfo(selectedItem: currentSelectedItem)
    }

    let detailsViewModel = DetailsViewModel(detailInfo: DetailInfo(type: .empty))

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

    func updateDetailInfo(selectedItem: SelectedItem?) {
        guard selectedItem != currentSelectedItem else { return }
        Task {
            await MainActor.run {
                guard let selectedItem else {
                    currentDetailInfo = nil
                    detailsViewModel.detailInfo = DetailInfo(type: .empty)
                    return
                }
                switch selectedItem.selectedItemType {
                case .regular(let type):
                    switch type {
                    case .stash(let item):
                        currentDetailInfo = DetailInfo(type: .stash(item))
                    case .status(let item):
                        currentDetailInfo = DetailInfo(type: .status(item))
                    case .commit(let item):
                        currentDetailInfo = DetailInfo(type: .commit(item))
                    case .detachedCommit(let item):
                        currentDetailInfo = DetailInfo(type: .detachedCommit(item))
                    case .detachedTag(let item):
                        currentDetailInfo = DetailInfo(type: .detachedTag(item))
                    case .tag(let item):
                        currentDetailInfo = DetailInfo(type: .tag(item))
                    case .historyCommit(let item):
                        currentDetailInfo = DetailInfo(type: .historyCommit(item))
                    }
                case .wip(let wip):
                    switch wip {
                    case .wipCommit(let item):
                        guard let worktree = WipWorktree.get(for: item.repository) else {
                            fatalError(.impossible)
                        }
                        currentDetailInfo = DetailInfo(type: .wipCommit(item, worktree))
                    }
                }
                detailsViewModel.detailInfo = currentDetailInfo!
                print("detailInfo: \(String(describing: currentDetailInfo))")
            }
        }
    }

    func updateDeltaInfo(selectedItem: SelectedItem?) {
        Task {
            await MainActor.run {
                guard let selectedItem else {
                    currentDeltaInfo = nil
                    return
                }
                switch selectedItem.selectedItemType {
                case .regular(let type):
                    switch type {
                    case .stash(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    case .status(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    case .commit(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    case .detachedCommit(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    case .detachedTag(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    case .tag(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    case .historyCommit(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    }
                case .wip(let wip):
                    switch wip {
                    case .wipCommit(let item):
                        currentDeltaInfo = currentDeltaInfos[item.oid]
                    }
                }
                print("deltaInfo: \(String(describing: currentDeltaInfo))")
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
            case .added, .modified, .copied, .untracked:
                guard let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.invalid)
                }
                if stage {
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .deleted:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path else {
                    fatalError(.invalid)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                }
            case .renamed, .typeChange:
                guard let oldFilePath = deltaInfo.delta.oldFile?.path,
                      let newFilePath = deltaInfo.delta.newFile?.path else {
                    fatalError(.invalid)
                }
                if stage {
                    repository.stage(path: oldFilePath).mustSucceed()
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    repository.unstage(path: oldFilePath).mustSucceed()
                    repository.unstage(path: newFilePath).mustSucceed()
                }
            case .ignored, .unreadable, .conflicted:
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

    func splitAndCommitTapped(repository: Repository, message: String) -> Commit {
        fatalError(.unimplemented)
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
}
