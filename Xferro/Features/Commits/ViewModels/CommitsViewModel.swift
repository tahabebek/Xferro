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

    // use the func setCurrentSelectedItem to set currentSelectedItem
    var currentSelectedItem: SelectedItem?

    func setCurrentSelectedItem(itemAndHead: (selectedItem: SelectedItem, head: Head)?) {
        user.lastSelectedRepositoryPath = itemAndHead?.selectedItem.repository.gitDir.path
        if let itemAndHead {
            updateWipCommits(selectedItem: itemAndHead.selectedItem, head: itemAndHead.head)
        } else {
            updateWipCommits()
        }
        currentSelectedItem = itemAndHead?.selectedItem
        updateDetailInfo()
    }

    var currentWipCommits: CurrentWipCommits?
    var currentDetailInfo: DetailInfo?
    let detailsViewModel: DetailsViewModel = .init(detailInfo: .init(type: .empty))

    var currentRepositoryInfos: OrderedDictionary<String, RepositoryInfo> = [:]
    private let statusManager: StatusManager
    private let userDidSelectFolder: (URL) -> Void
    private let user: User
    private let fileComparator: any FileComparator

    init(
        repositories: [Repository],
        statusManager: StatusManager = .shared,
        user: User,
        fileComparator: any FileComparator = FileManagerComparator(),
        userDidSelectFolder: @escaping (URL) -> Void
    ) {
        if UserDefaults.standard.object(forKey: "autoCommitEnabled") == nil {
            self.autoCommitEnabled = true
        } else {
            self.autoCommitEnabled = UserDefaults.standard.bool(forKey: "autoCommitEnabled")
        }
        self.statusManager = statusManager
        self.userDidSelectFolder = userDidSelectFolder
        self.user = user
        self.fileComparator = fileComparator

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
        let start = CFAbsoluteTimeGetCurrent()
        let repositoryInfo = await getRepositoryInfo(repository)
        await MainActor.run { [start] in
            currentRepositoryInfos[kRepositoryInfo(repository)] = repositoryInfo
            let diff = CFAbsoluteTimeGetCurrent() - start
            print("update repository info took \(diff)s for \(repository.gitDir.deletingLastPathComponent().lastPathComponent)")
        }
    }

    func updateDetailInfo() {
        Task {
            await MainActor.run {
                guard let currentSelectedItem else {
                    currentDetailInfo = nil
                    detailsViewModel.detailInfo = DetailInfo(type: .empty)
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
                                .status(SelectableStatus(repository: repositoryInfo.repository, head: repositoryInfo.head))
                            )
                        )
                        setCurrentSelectedItem(itemAndHead: (selectedItem, repositoryInfo.head))
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
    private func updateWipCommits(
        selectedItem: SelectedItem? = nil,
        worktree: WipWorktree? = nil,
        head: Head? = nil
    ) {
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
        else if let selectedItem, let head {
            switch selectedItem.selectedItemType {
            case .regular(let type):
                switch type {
                case .stash:
                    Task {
                        await MainActor.run {
                            currentWipCommits = nil
                        }
                    }
                case .status:
                    let selectableItem = selectedItem.selectableItem
                    let branchName = WipWorktree.worktreeBranchName(item: selectableItem)
                    let worktree = WipWorktree.getOrCreate(for: selectableItem, head: head)
                    if let worktree, worktree.getBranch(branchName: branchName) == nil {
                        worktree.createBranch(branchName: branchName, oid: selectableItem.oid)
                        worktree.checkout(branchName: branchName)
                    }

                    if let worktree {
                        let wipCommits =  worktree.commits(of: branchName, stop: selectableItem.oid)
                        Task {
                            await MainActor.run {
                                currentWipCommits = CurrentWipCommits(commits: wipCommits, item: selectedItem)
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
                    guard let worktree = WipWorktree.getOrCreate(for: selectedItem.selectableItem, head: head),
                          worktree.getBranch(branchName: WipWorktree.worktreeBranchName(item: selectedItem.selectableItem)) != nil
                    else {
                        Task {
                            await MainActor.run {
                                currentWipCommits = nil
                            }
                        }
                        return
                    }
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

    let wipCommitLock = NSRecursiveLock()
    private func addWipCommit(repository: Repository) {
        wipCommitLock.lock()
        defer { wipCommitLock.unlock() }
        let start = CFAbsoluteTimeGetCurrent()
        let head = Head.of(repository)
        let selectableItem = SelectableStatus(repository: repository, head: head)
        guard let worktree = WipWorktree.getOrCreate(for: selectableItem, head: head) else { return }
        let branchName = WipWorktree.worktreeBranchName(item: selectableItem)
        if worktree.getBranch(branchName: branchName) == nil {
            worktree.createBranch(branchName: branchName, oid: selectableItem.oid)
            worktree.checkout(branchName: branchName)
        }
        let worktreeRepositoryURL = WipWorktree.worktreeRepositoryURL(originalRepository: repository)
        let statusEntries = statusManager.status(of: repository)
        let wipWorktreePath = worktreeRepositoryURL.path
        let originalRepoPath = repository.gitDir.deletingLastPathComponent().path

        #warning("keep a set of tracked file urls, if user adds a new file and then deletes it later before committing, it will disappear from the status, so we need to delete it. Same for track and untrack/ignore later before committing.")
        let handleDelta: (Diff.Delta) -> Void = { [weak self] delta in
            guard let self else { return }
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
                        if FileManager.default.fileExists(atPath: sourceURL.path),
                           !fileComparator.contentsEqual(sourceURL, destinationURL)
                        {
                            print("FileManager: writing file \(newPath)")
                            try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        }
                    }
                }
            case .deleted:
                if let oldPath = delta.oldFile?.path {
                    if FileManager.default.fileExists(atPath: wipWorktreePath + "/" + oldPath) {
                        print("FileManager: removing file \(oldPath)")
                        try! FileManager.default.removeItem(atPath: wipWorktreePath + "/" + oldPath)
                    }
                }
            case .modified:
                if let path = delta.newFile?.path ?? delta.oldFile?.path {
                    let sourceURL = URL(filePath: originalRepoPath + "/" + path)
                    let destinationURL = URL(fileURLWithPath: wipWorktreePath + "/" + path)
                    if FileManager.default.fileExists(atPath: sourceURL.path),
                       !fileComparator.contentsEqual(sourceURL, destinationURL)
                    {
                        print("FileManager: writing file \(path)")
                        let content = try! Data(contentsOf: sourceURL)
                        try! content.write(to: destinationURL)
                    }
                }
            case .renamed:
                if let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: wipWorktreePath + "/" + oldPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if FileManager.default.fileExists(atPath: sourceURL.path),
                       !fileComparator.contentsEqual(sourceURL, destinationURL)
                        {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            print("FileManager: writing file \(newPath)")
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        } else {
                            print("FileManager: moving file \(newPath)")
                            try! FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                            try! FileManager.default.moveItem(atPath: sourceURL.path, toPath: destinationURL.path)
                        }
                    }
                }
            case .copied:
                if let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: wipWorktreePath + "/" + oldPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if FileManager.default.fileExists(atPath: sourceURL.path),
                       !fileComparator.contentsEqual(sourceURL, destinationURL)
                    {
                        print("FileManager: copying file \(newPath)")
                        try! FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                        try! FileManager.default.copyItem(atPath: sourceURL.path, toPath: destinationURL.path)
                    }
                }
            case .ignored:
                let sourceURL = URL(filePath: originalRepoPath + "/" + ".gitignore")
                let destinationURL = URL(filePath: wipWorktreePath + "/" + ".gitignore")
                if FileManager.default.fileExists(atPath: sourceURL.path),
                   !fileComparator.contentsEqual(sourceURL, destinationURL)
                {
                    print("FileManager: writing file \(destinationURL)")
                    let content = try! Data(contentsOf: sourceURL)
                    try! content.write(to: destinationURL)
                }
            case .untracked:
                // not writing untracked files, it could be undesirable.
                break
//                if let newPath = delta.newFile?.path {
//                    let sourceURL = URL(filePath: originalRepoPath + "/" + newPath)
//                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
//                    if destinationURL.isDirectory {
//                        try? FileManager.default.createDirectory(atPath: destinationURL.path, withIntermediateDirectories: true)
//                    } else {
//                        if FileManager.default.fileExists(atPath: sourceURL.path),
//                           !fileComparator.contentsEqual(sourceURL, destinationURL)
//                        {
//                            print("FileManager: writing file \(newPath)")
//                            try? FileManager.default.createDirectory(atPath: destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
//                            let content = try! Data(contentsOf: sourceURL)
//                            try! content.write(to: destinationURL)
//                        }
//                    }
//                }
            case .typeChange:
                if let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                    let sourceURL = URL(filePath: wipWorktreePath + "/" + oldPath)
                    let destinationURL = URL(filePath: wipWorktreePath + "/" + newPath)
                    if FileManager.default.fileExists(atPath: sourceURL.path),
                       !fileComparator.contentsEqual(sourceURL, destinationURL)
                    {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            print("FileManager: writing file \(newPath)")
                            let content = try! Data(contentsOf: sourceURL)
                            try! content.write(to: destinationURL)
                        } else {
                            print("FileManager: moving file \(newPath)")
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
        reloadUIAfterAddingWipCommits(
            repository: repository,
            worktree: worktree,
            head: head
        )
    }

    func reloadUIAfterAddingWipCommits(repository: Repository, worktree: WipWorktree, head: Head) {
        if let currentSelectedItem, repository.gitDir.path == currentSelectedItem.repository.gitDir.path {
            var isHead = false
            let headId = head.oid
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
                        updateWipCommits(
                            selectedItem: currentSelectedItem,
                            worktree: worktree,
                            head: head
                        )
                    }
                }
            }
        }

    }

    // MARK: Folder Observers
//    private func setupGitObserver(for repository: Repository) async {
//        let start = CFAbsoluteTimeGetCurrent()
//        let kGitWatcher = kGitWatcher(repository)
//        let kGitObserver = kGitObserver(repository)
//        if gitFolderWatchers[kGitWatcher] == nil {
//            let gitDir = repository.gitDir
//            let changeObserver = PassthroughSubject<Void, Never>()
//            gitFolderObservers[kGitObserver] = changeObserver
//                .debounce(for: 1, scheduler: RunLoop.main)
//                .sink { [weak self] in
//                    print("--------------------------")
//                    print("git changed for repository \(gitDir.deletingLastPathComponent().lastPathComponent)")
//                    Task {
//                        await self?.updateRepositoryInfo(repository)
//                        await MainActor.run { [weak self] in
//                            guard let self else { return }
//                            if let currentSelectedItem {
//                                if case .regular(let item) = currentSelectedItem.selectedItemType {
//                                    if case .status(let selectableStatus) = item {
//                                        if gitDir.path == selectableStatus.repository.gitDir.path {
//                                            let head = Head.of(selectableStatus.repository)
//                                            let selectedItem = SelectedItem(selectedItemType: .regular(.status(selectableStatus)))
//                                            self.setCurrentSelectedItem(itemAndHead: (selectedItem, head))
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//
//            gitFolderWatchers[kGitWatcher] = FolderWatcher(
//                folder: repository.gitDir,
//                includingPaths: [
//                    "\(gitDir.path)",
//                    "\(gitDir.path)/refs",
//                    "\(gitDir.path)/refs/heads",
//                    "\(gitDir.path)/refs/tags",
//                    "\(gitDir.path)/refs/remotes",
//                    "\(gitDir.path)/refs/notes",
//                    "\(gitDir.path)/logs",
//                    "\(gitDir.path)/logs/refs",
//                    "\(gitDir.path)/logs/refs/heads",
//                    "\(gitDir.path)/logs/refs/tags",
//                    "\(gitDir.path)/logs/refs/remotes",
//                    "\(gitDir.path)/logs/refs/notes",
//                    "\(gitDir.path)/hooks",
//                    "\(gitDir.path)/worktrees",
//                ],
//                onChangeObserver: changeObserver,
//                debugEnabled: true
//            )
//        }
//        let diff = CFAbsoluteTimeGetCurrent() - start
//        print("setup git observer took \(diff)s for \(repository.gitDir.deletingLastPathComponent().lastPathComponent)")
//    }

//    private func setupFolderObserver(for repository: Repository) async {
//        let start = CFAbsoluteTimeGetCurrent()
//        let kFolderWatcher = kFolderWatcher(repository)
//        let kFolderObserver = kFolderObserver(repository)
//        if repositoryFolderWatchers[kFolderWatcher] == nil {
//            let changeObserver = PassthroughSubject<Void, Never>()
//            repositoryFolderObservers[kFolderObserver] = changeObserver
//                .debounce(for: 1, scheduler: RunLoop.main)
//                .sink { [weak self] diff in
//                    guard let self else { return }
//                    guard autoCommitEnabled else { return }
//                    addWipCommit(repository: repository)
//                }
//
//            repositoryFolderWatchers[kFolderWatcher] = FolderWatcher(
//                folder: repository.gitDir.deletingLastPathComponent(),
//                excludingPaths: [repository.gitDir.path],
//                onChangeObserver: changeObserver,
//                debugEnabled: true
//            )
//
//        }
//        let diff = CFAbsoluteTimeGetCurrent() - start
//        print("setup folder observer took \(diff)s for \(repository.gitDir.deletingLastPathComponent().lastPathComponent)")
//    }

    // MARK: User actions
    func userTapped(item: any SelectableItem) {
        let head = Head.of(item.repository)
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
                setCurrentSelectedItem(itemAndHead: (selectedItem, head))
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
                        setCurrentSelectedItem(itemAndHead: nil)
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
                    print("stage \(newFilePath)")
                    repository.stage(path: newFilePath).mustSucceed()
                } else {
                    print("unstage \(newFilePath)")
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
        var newMessage = message
        if newMessage == nil || (newMessage ?? "").isEmptyOrWhitespace {
            let headCommit: Commit = repository.commit().mustSucceed()
            newMessage = headCommit.summary
        }

        guard let newMessage, !newMessage.isEmptyOrWhitespace else {
            fatalError(.unsupported)
        }
        repository.amend(message: newMessage).mustSucceed()
    }

    func ignoreButtonTapped(repository: Repository, deltaInfo: DeltaInfo) {
        guard let url = deltaInfo.newFileURL else {
            fatalError(.illegal)
        }

        guard let path = deltaInfo.newFilePath else {
            fatalError(.illegal)
        }
        repository.ignore(path)
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
