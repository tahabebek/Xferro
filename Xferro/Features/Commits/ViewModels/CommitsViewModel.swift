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
        currentSelectedItem = selectedItem
    }
    
    var currentWipCommits: WipCommits?
    var currentRepositoryInfos: OrderedDictionary<String, RepositoryViewModel> = [:]
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

    private func setupInitialCurrentSelectedItem() {
        Task {
            await MainActor.run {
                guard currentSelectedItem == nil else { return }
                if !currentRepositoryInfos.isEmpty {
                    var repositoryInfo: RepositoryViewModel?
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
                            type: .regular(
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
            if case .regular(.status(let currentStatus)) = currentSelectedItem?.type {
                return status == currentStatus
            } else {
                return false
            }
        case let commit as SelectableCommit:
            if case .regular(.commit(let currentCommit)) = currentSelectedItem?.type  {
                return commit == currentCommit
            } else {
                return false
            }
        case let wipCommit as SelectableWipCommit:
            if case .wip(.wipCommit(let currentWipCommit)) = currentSelectedItem?.type  {
                return wipCommit == currentWipCommit
            } else {
                return false
            }
        case let historyCommit as SelectableHistoryCommit:
            if case .regular(.historyCommit(let currentHistoryCommit)) = currentSelectedItem?.type  {
                return historyCommit == currentHistoryCommit
            } else {
                return false
            }
        case let detachedCommit as SelectableDetachedCommit:
            if case .regular(.detachedCommit(let currentDetachedCommit)) = currentSelectedItem?.type  {
                return detachedCommit == currentDetachedCommit
            } else {
                return false
            }
        case let detachedTag as SelectableDetachedTag:
            if case .regular(.detachedTag(let currentDetachedTag)) = currentSelectedItem?.type  {
                return detachedTag == currentDetachedTag
            } else {
                return false
            }
        case let tag as SelectableTag:
            if case .regular(.tag(let currentTag)) = currentSelectedItem?.type  {
                return tag == currentTag
            } else {
                return false
            }
        case let stash as SelectableStash:
            if case .regular(.stash(let currentStash)) = currentSelectedItem?.type  {
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
                    selectedItem = .init(type: .regular(.status(status)))
                case let commit as SelectableCommit:
                    selectedItem = .init(type: .regular(.commit(commit)))
                case let wipCommit as SelectableWipCommit:
                    selectedItem = .init(type: .wip(.wipCommit(wipCommit)))
                case let historyCommit as SelectableHistoryCommit:
                    selectedItem = .init(type: .regular(.historyCommit(historyCommit)))
                case let detachedCommit as SelectableDetachedCommit:
                    selectedItem = .init(type: .regular(.detachedCommit(detachedCommit)))
                case let detachedTag as SelectableDetachedTag:
                    selectedItem = .init(type: .regular(.detachedTag(detachedTag)))
                case let tag as SelectableTag:
                    selectedItem = .init(type: .regular(.tag(tag)))
                case let stash as SelectableStash:
                    selectedItem = .init(type: .regular(.stash(stash)))
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
}
