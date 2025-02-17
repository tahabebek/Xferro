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
        let item: SelectedItem
    }

    var autoCommitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCommitEnabled, forKey: "autoCommitEnabled")
        }
    }

    var currentSelectedItem: SelectedItem? {
        didSet {
            updateDetailInfo()
            updateWipCommitsForCurrentSelectedItem()
        }
    }
    var currentRepositoryInfos: OrderedDictionary<String, RepositoryInfo> = [:]
    var currentWipCommits: CurrentWipCommits?
    var currentDetailInfo: DetailInfo?

    let detailsViewModel: DetailsViewModel = .init(detailInfo: .init(type: .empty))

    private var gitFolderWatchers: [String: FolderWatcher] = [:]
    private var repsositoryFolderWatchers: [String: FolderWatcher] = [:]
    private var repositoryViewModels: Dictionary<String, RepositoryViewModel> = [:]
    private let statusManager: StatusManager
    private let userDidSelectFolder: (URL) -> Void
    private var folderChangeObservers: Set<AnyCancellable> = []

    init(
        repositories: [Repository],
        statusManager: StatusManager = .shared,
        userDidSelectFolder: @escaping (URL) -> Void
    ) {
        if UserDefaults.standard.object(forKey: "autoCommitEnabled") == nil {
            self.autoCommitEnabled = true
        } else {
            self.autoCommitEnabled = UserDefaults.standard.bool(forKey: "autoCommitEnabled")
        }
        self.statusManager = statusManager
        self.userDidSelectFolder = userDidSelectFolder
        for repository in repositories {
            addRepository(repository)
        }
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
        if let repositoryViewModel = repositoryViewModels[keyForRepositoryInfos(repository)] {
            repositoryViewModel.repositoryInfo = repositoryInfo
            return repositoryViewModel
        }
        let newRepositoryViewModel: RepositoryViewModel = .init(repositoryInfo: repositoryInfo)
        repositoryViewModels[keyForRepositoryInfos(repository)] = newRepositoryViewModel
        return newRepositoryViewModel
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

    private func updateDetailInfo() {
        Task {
            await MainActor.run {
                guard let currentSelectedItem else {
                    currentDetailInfo = nil
                    return
                }
                switch currentSelectedItem.selectedItemType {
                case .regular(let type):
                    switch type {
                    case .stash(let stash):
                        currentDetailInfo = DetailInfo(type: .stash(stash))
                    case .status(let status):
                        let statusEntries = statusManager.status(of: currentSelectedItem.repository)
                        currentDetailInfo = DetailInfo(type: .status(status, statusEntries))
                    case .commit(let commit):
                        currentDetailInfo = DetailInfo(type: .commit(commit))
                    case .detachedCommit(let commit):
                        currentDetailInfo = DetailInfo(type: .detachedCommit(commit))
                    case .detachedTag(let tag):
                        currentDetailInfo = DetailInfo(type: .detachedTag(tag))
                    case .tag(let tag):
                        currentDetailInfo = DetailInfo(type: .tag(tag))
                    case .historyCommit(let commit):
                        currentDetailInfo = DetailInfo(type: .historyCommit(commit))
                    }
                case .wip(let wip):
                    switch wip {
                    case .wipCommit(let commit):
                        guard let worktree = WipWorktree.get(for: commit.repository) else {
                            fatalError(.impossible)
                        }
                        currentDetailInfo = DetailInfo(type: .wipCommit(commit, worktree))
                    }
                }
                detailsViewModel.detailInfo = currentDetailInfo!
            }
        }
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

    // MARK: Wip
    private func updateWipCommitsForCurrentSelectedItem(selectedItem: SelectedItem? = nil, worktree: WipWorktree? = nil) {
        if let selectedItem, let worktree {
            let wipCommits =  worktree.commits(
                of: WipWorktree.worktreeBranchName(item: selectedItem.selectableItem),
                stop: selectedItem.selectableItem.oid
            )
            Task {
                await MainActor.run {
                    currentWipCommits = CurrentWipCommits(commits: wipCommits, item: selectedItem)
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
                            currentWipCommits = nil
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
                        Task {
                            await MainActor.run {
                                currentWipCommits = CurrentWipCommits(commits: wipCommits, item: currentSelectedItem)
                            }
                        }

                    } else {
                        Task {
                            await MainActor.run {
                                currentWipCommits = nil
                            }
                        }
                    }
                default:
                    guard let worktree = WipWorktree.getOrCreate(for: currentSelectedItem.selectableItem),
                          worktree.getBranch(branchName: WipWorktree.worktreeBranchName(item: currentSelectedItem.selectableItem)) != nil
                    else {
                        Task {
                            await MainActor.run {
                                currentWipCommits = nil
                            }
                        }
                        return
                    }
                    let wipCommits =  worktree.commits(
                        of: WipWorktree.worktreeBranchName(item: currentSelectedItem.selectableItem),
                        stop: currentSelectedItem.selectableItem.oid
                    )
                    Task {
                        await MainActor.run {
                            currentWipCommits = CurrentWipCommits(commits: wipCommits, item: currentSelectedItem)
                        }
                    }
                }
            case .wip:
                break
            }
        } else {
            Task {
                await MainActor.run {
                    currentWipCommits = nil
                }
            }
        }
    }

    func deleteWipWorktreeTapped(for repository: Repository) {
        deleteWipWorktree(for: repository)
    }

    private func deleteWipWorktree(for repository: Repository) {
        WipWorktree.deleteWipWorktree(for: repository)
        currentWipCommits = nil
    }

    func deleteAllWipCommitsTapped(for item: SelectedItem) {
        deleteAllWipCommits(of: item)
    }

    private func deleteAllWipCommits(of item: SelectedItem) {
        WipWorktree.deleteAllWipCommits(of: item)
        Task {
            await MainActor.run {
                currentWipCommits = nil
            }
        }
    }

    func addManualWipCommitTapped(for item: SelectedItem) {
        addManualWipCommit(for: item)
    }
    private func addManualWipCommit(for item: SelectedItem) {
        addWipCommit(repository: item.repository)
    }

    private func addWipCommit(repository: Repository) {
        let worktreeRepositoryURL = WipWorktree.worktreeRepositoryURL(originalRepository: repository)
        let selectableItem = SelectableStatus(repository: repository)
        guard let worktree = WipWorktree.getOrCreate(for: selectableItem) else { return }
        let branchName = WipWorktree.worktreeBranchName(item: selectableItem)
        if worktree.getBranch(branchName: branchName) == nil {
            worktree.createBranch(branchName: branchName, oid: selectableItem.oid)
            worktree.checkout(branchName: branchName)
        }
        let statusEntries = statusManager.status(of: repository)
        let wipWorktreePath = worktreeRepositoryURL.path
        let originalRepoPath = repository.gitDir.deletingLastPathComponent().path

        let handleDelta: (Diff.Delta) -> Void = { delta in
            print("---------------------------------------")
            switch delta.status {
            case .unmodified:
                break
            case .added:
                if let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: originalRepoPath + "/" + newPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if destinationURL.isDirectory {
                        try? FileManager.default.createDirectory(atPath: destinationURL.path, withIntermediateDirectories: true)
                    } else {
                        if FileManager.default.fileExists(atPath: sourceURL.path) {
                            try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        }
                    }
                }
            case .deleted:
                if let oldPath = delta.oldFile?.path {
                    if FileManager.default.fileExists(atPath: wipWorktreePath + "/" + oldPath) {
                        try! FileManager.default.removeItem(atPath: wipWorktreePath + "/" + oldPath)
                    }
                }
            case .modified:
                if let path = delta.newFile?.path ?? delta.oldFile?.path {
                    let sourceURL = URL(filePath: originalRepoPath + "/" + path)
                    let destinationURL = URL(fileURLWithPath: wipWorktreePath + "/" + path)
                    if FileManager.default.fileExists(atPath: sourceURL.path) {
                        let content = try! Data(contentsOf: sourceURL)
                        try! content.write(to: destinationURL)
                    }
                }
            case .renamed:
                if let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: wipWorktreePath + "/" + oldPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if FileManager.default.fileExists(atPath: sourceURL.path) {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        } else {
                            try! FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            try! FileManager.default.moveItem(atPath: sourceURL.path, toPath: destinationURL.path)
                        }
                    }
                }
            case .copied:
                if let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: wipWorktreePath + "/" + oldPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if FileManager.default.fileExists(atPath: sourceURL.path) {
                        try! FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                        try! FileManager.default.copyItem(atPath: sourceURL.path, toPath: destinationURL.path)
                    }
                }
            case .ignored:
                let sourceURL = URL(filePath: originalRepoPath + "/" + ".gitignore")
                let destinationURL = URL(filePath: wipWorktreePath + "/" + ".gitignore")
                if FileManager.default.fileExists(atPath: sourceURL.path) {
                    let content = try! Data(contentsOf: sourceURL)
                    try! content.write(to: destinationURL)
                }
            case .untracked:
                if let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: originalRepoPath + "/" + newPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if destinationURL.isDirectory {
                        try? FileManager.default.createDirectory(atPath: destinationURL.path, withIntermediateDirectories: true)
                    } else {
                        if FileManager.default.fileExists(atPath: sourceURL.path) {
                            try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        }
                    }
                }
            case .typeChange:
                if let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: wipWorktreePath + "/" + oldPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if FileManager.default.fileExists(atPath: sourceURL.path) {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        } else {
                            try! FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            try! FileManager.default.moveItem(atPath: sourceURL.path, toPath: destinationURL.path)
                        }
                    }
                }
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }

        for statusEntry in statusEntries {
            var handled: Bool = false
            if let stagedDelta = statusEntry.stagedDelta {
                handled = true
                debugPrint(stagedDelta)
                handleDelta(stagedDelta)
            }

            if let unstagedDelta = statusEntry.unstagedDelta {
                handled = true
                debugPrint(unstagedDelta)
                handleDelta(unstagedDelta)
            }

            guard handled else {
                fatalError(.unimplemented)
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
                        updateDetailInfo()
                        updateWipCommitsForCurrentSelectedItem(selectedItem: currentSelectedItem, worktree: worktree)
                    }
                }
            }
        }
    }

    // MARK: Folder Observers
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
        addWipCommit(repository: repository)
    }

    // MARK: User actions
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

    // MARK: Keys
    private func keyForRepositoryGitWatch(_ repository: Repository) -> String {
        String(repository.id.hashValue)
    }
    private func keyForRepositoryFolderWatch(_ repository: Repository) -> String {
        String(repository.id.hashValue)
    }
    private func keyForRepositoryInfos(_ repository: Repository) -> String {
        String(repository.id.hashValue)
    }
}
