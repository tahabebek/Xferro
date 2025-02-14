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

@Observable class CommitsViewModel {
    struct CurrentWipCommits {
        let commits: [SelectableWipCommit]
        let title: String
    }

    var autoCommitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCommitEnabled, forKey: "autoCommitEnabled")
        }
    }

    var currentSelectedItem: SelectedItem? {
        didSet {
            updateWipCommitsForCurrentSelectedItem()
        }
    }
    var currentRepositoryInfos: OrderedDictionary<String, RepositoryInfo> = [:]
    var currentWipCommits: CurrentWipCommits = CurrentWipCommits(commits: [], title: "")
    private var gitFolderWatchers: [String: FolderWatcher] = [:]
    private var repsositoryFolderWatchers: [String: FolderWatcher] = [:]
    private let userDidSelectFolder: (URL) -> Void
    private var folderChangeObservers: Set<AnyCancellable> = []

    init(repositories: [Repository], userDidSelectFolder: @escaping (URL) -> Void) {
        if UserDefaults.standard.object(forKey: "autoCommitEnabled") == nil {
            self.autoCommitEnabled = true
        } else {
            self.autoCommitEnabled = UserDefaults.standard.bool(forKey: "autoCommitEnabled")
        }
        self.userDidSelectFolder = userDidSelectFolder
        for repository in repositories {
            addRepository(repository)
        }
    }

    func deleteWipWorktree(for repository: Repository) {
        let worktreeName = WipWorktree.worktreeName(for: repository)
        guard let worktreePath = try? repository.worktreePath(by: worktreeName).get() else {
            fatalError(.invalid)
        }
        print("deleting worktree...: \(worktreePath)")
        _ = repository.pruneWorkTree(worktreeName, force: true).mustSucceed()
        try! FileManager.default.removeItem(at: URL(filePath: worktreePath, directoryHint: .isDirectory))

        let branchIterator = BranchIterator(repo: repository, type: .local)
        while let branch = try? branchIterator.next()?.get() {
            if branch.name.hasPrefix(WipWorktree.wipBranchesPrefix) {
                print("deleting branch...: \(branch.name)")
                repository.deleteBranch(branch.name).mustSucceed()
            }
        }
        currentWipCommits = .init(commits: [], title: "")
    }

    func deleteAllWipCommits(of item: SelectedItem) {
        let worktreeRepositoryURL = WipWorktree.worktreeRepositoryURL(originalRepository: item.repository)
        guard Repository.isGitRepository(url: worktreeRepositoryURL).mustSucceed() else {
            fatalError(.impossible)
        }
        let worktreeRepository = Repository.at(worktreeRepositoryURL).mustSucceed()
        guard worktreeRepository.isWorkTree else {
            fatalError(.illegal)
        }
        let worktreeName = WipWorktree.worktreeName(for: item.repository)

        let head = Head.of(worktree: worktreeName, in: item.repository)
        var currentBranchName: String? = nil

        switch head {
        case .branch(let branch):
            currentBranchName = branch.shortName
        case .tag:
            fatalError("Head should never be a tag for a worktree")
        case .reference:
            fatalError("Head should never be detached for a worktree.")
            break
        }

        print(currentBranchName!)
        var shouldDeleteBranch = true
        switch item.selectedItemType {
        case .regular(let type):
            switch type {
            case .commit(let selectableCommit):
                print(selectableCommit.oid.debugOID.prefix(4))
                print(WipWorktree.worktreeBranchName(item: item.selectableItem))
                if currentBranchName == WipWorktree.worktreeBranchName(item: item.selectableItem) {
                    shouldDeleteBranch = false
                }
            case .historyCommit, .detachedCommit, .detachedTag, .tag, .status:
                print("something else")
                shouldDeleteBranch = false
            case .stash:
                fatalError(.invalid)
            }
        case .wip:
            fatalError(.invalid)
        }

        let branchName = WipWorktree.worktreeBranchName(item: item.selectableItem)
        if shouldDeleteBranch {
            item.repository.deleteBranch(branchName).mustSucceed()
        } else {
            worktreeRepository.reset(oid: item.selectableItem.oid , type: .hard).mustSucceed()
        }
        Task {
            await MainActor.run {
                currentWipCommits = .init(commits: [], title: "")
            }
        }
    }

    func addManualCommit(for item: SelectedItem) {

    }

    func addRepository(_ repository: Repository) {
        var head = try? repository.HEAD().get()
        if head == nil {
            repository.createEmptyCommit()
            head = try? repository.HEAD().get()
        }

        guard head != nil else {
            fatalError(.illegal)
        }
        setupGitObserver(for: repository)
        setupFolderObserver(for: repository)
        updateRepositoryInfo(repository)
    }

    func repositoryViewModel(for repository: Repository) -> RepositoryViewModel {
        guard let repositoryInfo = currentRepositoryInfos[keyForRepositoryInfos(repository)] else {
            fatalError(.unexpected)
        }
        return RepositoryViewModel(repositoryInfo: repositoryInfo)
    }

    private func keyForRepositoryGitWatch(_ repository: Repository) -> String {
        String(repository.id.hashValue)
    }
    private func keyForRepositoryFolderWatch(_ repository: Repository) -> String {
        String(repository.id.hashValue)
    }
    private func keyForRepositoryInfos(_ repository: Repository) -> String {
        String(repository.id.hashValue)
    }

    private func updateRepositoryInfo(_ repository: Repository) {
        Task {
            await MainActor.run {
                let repositoryInfo = getRepositoryInfo(repository)
                currentRepositoryInfos[keyForRepositoryInfos(repository)] = repositoryInfo
                setupInitialCurrentSelectedItem()
            }
        }
    }

    private func updateWipCommitsForCurrentSelectedItem(selectedItem: SelectedItem? = nil, worktree: WipWorktree? = nil) {
        if let selectedItem, let worktree {
            let wipCommits =  worktree.commits(
                of: WipWorktree.worktreeBranchName(item: selectedItem.selectableItem),
                stop: selectedItem.selectableItem.oid
            )
            let wipCommitTitle = "Wip commits of \(selectedItem.selectableItem.wipDescription)"
            Task {
                await MainActor.run {
                    currentWipCommits = CurrentWipCommits(commits: wipCommits, title: wipCommitTitle)
                }
            }
        }
        else if let currentSelectedItem {
            switch currentSelectedItem.selectedItemType {
            case .regular(let type):
                switch type {
                case .stash:
                    Task {
                        await MainActor.run {
                            currentWipCommits = CurrentWipCommits(commits: [], title: "Stashes don't have wip commits")
                        }
                    }
                case .status:
                    let selectableItem = currentSelectedItem.selectableItem
                    let branchName = WipWorktree.worktreeBranchName(item: selectableItem)
                    let worktree = WipWorktree.getOrCreate(for: selectableItem)
                    if let worktree, worktree.getBranch(branchName: branchName) == nil {
                        worktree.createBranch(branchName: branchName, oid: selectableItem.oid)
                        worktree.checkout(branchName: branchName)
                    }

                    if let worktree {
                        let wipCommits =  worktree.commits(of: branchName, stop: selectableItem.oid)
                        let wipCommitTitle = "Wip commits of \(currentSelectedItem.selectableItem.wipDescription)"
                        Task {
                            await MainActor.run {
                                currentWipCommits = CurrentWipCommits(commits: wipCommits, title: wipCommitTitle)
                            }
                        }

                    } else {
                        Task {
                            await MainActor.run {
                                currentWipCommits = .init(commits: [], title: "")
                            }
                        }
                    }
                default:
                    guard let worktree = WipWorktree.getOrCreate(for: currentSelectedItem.selectableItem),
                          worktree.getBranch(branchName: WipWorktree.worktreeBranchName(item: currentSelectedItem.selectableItem)) != nil
                    else {
                        Task {
                            await MainActor.run {
                                currentWipCommits = .init(commits: [], title: "")
                            }
                        }
                        return
                    }
                    let wipCommits =  worktree.commits(
                        of: WipWorktree.worktreeBranchName(item: currentSelectedItem.selectableItem),
                        stop: currentSelectedItem.selectableItem.oid
                    )
                    let wipCommitTitle = "Wip commits of \(currentSelectedItem.selectableItem.wipDescription)"
                    Task {
                        await MainActor.run {
                            currentWipCommits = CurrentWipCommits(commits: wipCommits, title: wipCommitTitle)
                        }
                    }
                }
            case .wip:
                break
            }
        } else {
            Task {
                await MainActor.run {
                    currentWipCommits = .init(commits: [], title: "")
                }
            }
        }
    }

    private func setupGitObserver(for repository: Repository) {
        let key = keyForRepositoryGitWatch(repository)
        if gitFolderWatchers[key] == nil {
            let gitDir = repository.gitDir
            let changeObserver = PassthroughSubject<Void, Never>()
            changeObserver
                .debounce(for: 1, scheduler: RunLoop.main)
                .sink { [weak self] in
                    print("--------------------------")
                    print("git changed for repository \(gitDir.deletingLastPathComponent().lastPathComponent)")
                    Task {
                        await MainActor.run { [weak self] in
                            guard let self else { return }
                            updateRepositoryInfo(repository)
                        }
                    }
                }
                .store(in: &folderChangeObservers)

            gitFolderWatchers[key] = FolderWatcher(
                folder: gitDir,
                includingPaths: [
                    "\(gitDir.path)",
                    "\(gitDir.path)/config",
                    "\(gitDir.path)/HEAD",
                    "\(gitDir.path)/ORIG_HEAD",
                    "\(gitDir.path)/FETCH_HEAD",
                    "\(gitDir.path)/refs",
                    "\(gitDir.path)/refs/heads",
                    "\(gitDir.path)/refs/tags",
                    "\(gitDir.path)/refs/remotes",
                    "\(gitDir.path)/refs/notes",
                    "\(gitDir.path)/logs",
                    "\(gitDir.path)/logs/HEAD",
                    "\(gitDir.path)/logs/refs",
                    "\(gitDir.path)/logs/refs/heads",
                    "\(gitDir.path)/logs/refs/tags",
                    "\(gitDir.path)/logs/refs/remotes",
                    "\(gitDir.path)/logs/refs/notes",
                    "\(gitDir.path)/index"
                ],
                onChangeObserver: changeObserver
            )
        }
    }

    private func setupFolderObserver(for repository: Repository) {
        let key = keyForRepositoryFolderWatch(repository)
        if repsositoryFolderWatchers[key] == nil {
            let changeObserver = PassthroughSubject<Void, Never>()
            changeObserver
                .debounce(for: 1, scheduler: RunLoop.main)
                .sink { [weak self] in
                    guard let self else { return }
                    handleFolderWatchUpdate(repository: repository)
                }
                .store(in: &folderChangeObservers)

            repsositoryFolderWatchers[key] = FolderWatcher(
                folder: repository.gitDir.deletingLastPathComponent(),
                excludingPaths: [repository.gitDir.path],
                onChangeObserver: changeObserver
            )

        }
    }

    private func handleFolderWatchUpdate(repository: Repository) {
        guard autoCommitEnabled else { return }
        let worktreeRepositoryURL = WipWorktree.worktreeRepositoryURL(originalRepository: repository)
        let selectableItem = SelectableStatus(repository: repository)
        guard let worktree = WipWorktree.getOrCreate(for: selectableItem) else { return }
        let branchName = WipWorktree.worktreeBranchName(item: selectableItem)
        if worktree.getBranch(branchName: branchName) == nil {
            worktree.createBranch(branchName: branchName, oid: selectableItem.oid)
            worktree.checkout(branchName: branchName)
        }
        let statusEntries = repository.status().mustSucceed()
        let wipWorktreePath = worktreeRepositoryURL.path
        for statusEntry in statusEntries {
            let originalRepoPath = repository.gitDir.deletingLastPathComponent().path
            for (oldPath, newPath) in getPaths(from: statusEntry) {
                print("-------------------------")
                print("oldPath: \(oldPath ?? "nil"), newPath: \(newPath)")
                let status = statusEntry.status
                if status.contains(.indexNew) || status.contains(.workTreeNew) {
                    if let newPath {
                        let url = URL(filePath: newPath)
                        if url.isDirectory {
                            try! FileManager.default.createDirectory(atPath: wipWorktreePath + "/" + url.path, withIntermediateDirectories: true)
                        } else {
                            let content = try! Data(contentsOf: URL(filePath: originalRepoPath + "/" + newPath))
                            try! content.write(to: URL(fileURLWithPath: wipWorktreePath + "/" + newPath))
                        }
                    }
                } else if status.contains(.indexDeleted) || status.contains(.workTreeDeleted) {
                    if FileManager.default.fileExists(atPath: wipWorktreePath + "/" + oldPath!) {
                        try! FileManager.default.removeItem(atPath: wipWorktreePath + "/" + oldPath!)
                    }
                } else if status.contains(.indexRenamed) || status.contains(.workTreeRenamed) {
                    if FileManager.default.fileExists(atPath: wipWorktreePath + "/" + oldPath!) {
                        try! FileManager.default.moveItem(atPath: oldPath!, toPath: newPath!)
                    } else {
                        let content = try! Data(contentsOf: URL(filePath: originalRepoPath + "/" + newPath!))
                        try! FileManager.default.createDirectory(atPath: wipWorktreePath + "/" + URL(filePath: newPath!).deletingLastPathComponent().path, withIntermediateDirectories: true)
                        try! content.write(to: URL(fileURLWithPath: wipWorktreePath + "/" + newPath!))
                    }
                } else if status.contains(.indexModified) || status.contains(.workTreeModified) {
                    let path = newPath ?? oldPath!
                    let content = try! Data(contentsOf: URL(filePath: originalRepoPath + "/" + path))
                    try! content.write(to: URL(fileURLWithPath: wipWorktreePath + "/" + path))
                } else if status.contains(.indexTypeChange) || status.contains(.workTreeTypeChange) {
                    if FileManager.default.fileExists(atPath: wipWorktreePath + "/" + newPath!) {
                        try! FileManager.default.removeItem(atPath: wipWorktreePath + "/" + newPath!)
                    }
                    let content = try! Data(contentsOf: URL(filePath: originalRepoPath + "/" + newPath!))
                    try! content.write(to: URL(fileURLWithPath: wipWorktreePath + "/" + newPath!))
                }
            }
        }
        worktree.addToWorktreeIndex(path: ".")
        worktree.commit()
        if let currentSelectedItem, repository.gitDir.path == currentSelectedItem.repository.gitDir.path {
            var isHead = false
            let headId = Head.of(repository).oid
            switch currentSelectedItem.selectedItemType {
            case .regular(let type):
                switch type {
                case .status:
                    isHead = true
                case .commit(let selectableCommit):
                    if selectableCommit.oid == headId {
                        isHead = true
                    }
                case .historyCommit(let selectableHistoryCommit):
                    if selectableHistoryCommit.oid == headId {
                        isHead = true
                    }
                case .detachedCommit(let selectableDetachedCommit):
                    if selectableDetachedCommit.oid == headId {
                        isHead = true
                    }
                case .detachedTag(let selectableDetachedTag):
                    if selectableDetachedTag.oid == headId {
                        isHead = true
                    }
                case .tag(let selectableTag):
                    if selectableTag.oid == headId {
                        isHead = true
                    }
                case .stash:
                    break
                }
            case .wip:
                break
            }

            if isHead {
                Task {
                    await MainActor.run {
                        updateWipCommitsForCurrentSelectedItem(selectedItem: currentSelectedItem, worktree: worktree)
                    }
                }
            }
        }
    }

    private func getPaths(from entry: StatusEntry) -> [(old: String?, new: String?)] {
        var paths: [(old: String?, new: String?)] = []
        if let staged = entry.stagedChanges {
            paths.append((staged.oldFile?.path, staged.newFile?.path))
        }
        if let unstaged = entry.unstagedChanges {
            paths.append((unstaged.oldFile?.path, unstaged.newFile?.path))
        }
        return paths
    }

    private func setupInitialCurrentSelectedItem() {
        Task {
            await MainActor.run {
                guard currentSelectedItem == nil else { return }
                if !currentRepositoryInfos.isEmpty {
                    let firstRepo = currentRepositoryInfos.values[0].repository
                    currentSelectedItem = SelectedItem(
                        selectedItemType: .regular(
                            .status(SelectableStatus(repository: firstRepo))
                        )
                    )
                }
            }
        }
    }

    func userTapped(item: any SelectableItem) {
        Task {
            await MainActor.run {
                switch item {
                case let status as SelectableStatus:
                    currentSelectedItem = .init(selectedItemType: .regular(.status(status)))
                case let commit as SelectableCommit:
                    currentSelectedItem = .init(selectedItemType: .regular(.commit(commit)))
                case let wipCommit as SelectableWipCommit:
                    currentSelectedItem = .init(selectedItemType: .wip(.wipCommit(wipCommit)))
                case let historyCommit as SelectableHistoryCommit:
                    currentSelectedItem = .init(selectedItemType: .regular(.historyCommit(historyCommit)))
                case let detachedCommit as SelectableDetachedCommit:
                    currentSelectedItem = .init(selectedItemType: .regular(.detachedCommit(detachedCommit)))
                case let detachedTag as SelectableDetachedTag:
                    currentSelectedItem = .init(selectedItemType: .regular(.detachedTag(detachedTag)))
                case let tag as SelectableTag:
                    currentSelectedItem = .init(selectedItemType: .regular(.tag(tag)))
                case let stash as SelectableStash:
                    currentSelectedItem = .init(selectedItemType: .regular(.stash(stash)))
                default:
                    fatalError()
                }
            }
        }
    }

    func deleteBranchTapped(repository: Repository, branchName: String) {
        repository.deleteBranch(branchName).mustSucceed()
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
        guard currentRepositoryInfos[keyForRepositoryInfos(repository)] != nil else {
            fatalError(.unexpected)
        }
        Task {
            await MainActor.run {
                currentRepositoryInfos[keyForRepositoryInfos(repository)] = nil
            }
        }

    }

    func isCurrentBranch(_ branch: Branch, head: Head, in repository: Repository) -> Bool {
        switch head {
        case .branch(let headBranch):
            if branch == headBranch {
                return true
            }
        default:
            break
        }
        return false
    }
}
