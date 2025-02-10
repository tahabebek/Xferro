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

    var currentSelectedItem: SelectedItem? {
        didSet {
            updateWipCommits()
        }
    }

    var currentRepositoryInfos: OrderedDictionary<String, RepositoryInfo> = [:]
    var currentWipCommits: CurrentWipCommits = CurrentWipCommits(commits: [], title: "")
    private var gitFolderWatchers: [String: FolderWatcher] = [:]
    private var repsositoryFolderWatchers: [String: FolderWatcher] = [:]
    private let userDidSelectFolder: (URL) -> Void
    private var onGitFolderChangeObservers: Set<AnyCancellable> = []
    private var repositoryQueues: [String: DispatchQueue] = [:]
    private var userSelectedAnItem = false
    private var initialized: Bool = false

    init(repositories: [Repository], userDidSelectFolder: @escaping (URL) -> Void) {
        self.userDidSelectFolder = userDidSelectFolder
        for repository in repositories {
            self.addRepository(repository)
        }
        initialized = true
    }

    func addRepository(_ repository: Repository) {
        let key = keyForRepository(repository)
        if repositoryQueues[key] == nil {
            repositoryQueues[key] = DispatchQueue(label: "com.xferro.repository.\(key)")
        }

        setupGitObserver(for: repository)
        setupFolderObserver(for: repository)
        updateRepositoryInfo(repository)
        if initialized {
            userTapped(item: SelectableStatus(repository: repository))
        }
    }

    func repositoryViewModel(for repository: Repository) -> RepositoryViewModel {
        guard let repositoryInfo = currentRepositoryInfos[keyForRepository(repository)] else {
            fatalError(.unexpected)
        }
        return RepositoryViewModel(repositoryInfo: repositoryInfo)
    }

    private func keyForRepository(_ repository: Repository) -> String {
        guard let gitDir = repository.gitDir?.deletingLastPathComponent() else { fatalError(.impossible) }
        return gitDir.path
    }

    private func updateRepositoryInfo(_ repository: Repository) {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            let repositoryInfo = getRepositoryInfo(repository)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                currentRepositoryInfos[keyForRepository(repository)] = repositoryInfo
                setupInitialCurrentSelectedItem()
            }
        }
    }
    
    private func updateWipCommits(worktree: Worktree? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if currentSelectedItem != nil {
                switch currentSelectedItem!.selectedItemType {
                case .regular(let type):
                    switch type {
                    case .stash:
                        currentWipCommits = CurrentWipCommits(commits: [], title: "Stashes don't have wip commits")
                    default:
                        let wipCommits = wipCommits(of: currentSelectedItem!.selectableItem, worktree: worktree)
                        let wipCommitTitle = "Wip commits of \(currentSelectedItem!.selectableItem.wipDescription)"
                        currentWipCommits = CurrentWipCommits(commits: wipCommits, title: wipCommitTitle)
                    }
                case .wip:
                    break
                }
            } else {
                currentWipCommits = .init(commits: [], title: "")
            }
        }
    }

    private func setupGitObserver(for repository: Repository) {
        let key = keyForRepository(repository)
        if gitFolderWatchers[key] == nil {
            guard let gitDir = repository.gitDir else { fatalError() }
            let changeObserver = PassthroughSubject<Void, Never>()
            changeObserver
                .debounce(for: 1, scheduler: RunLoop.main)
                .sink { [weak self] in
                    guard let self else { return }
                    print("--------------------------")
                    print("git changed for repository \(gitDir.deletingLastPathComponent().lastPathComponent)")
                    setupInitialCurrentSelectedItem()
                    updateRepositoryInfo(repository)
                }
                .store(in: &onGitFolderChangeObservers)

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
        let key = keyForRepository(repository)
        if repsositoryFolderWatchers[key] == nil {
            guard let gitDir = repository.gitDir else { fatalError() }
            let changeObserver = PassthroughSubject<Void, Never>()
            let key = keyForRepository(repository)
            if repositoryQueues[key] == nil {
                repositoryQueues[key] = DispatchQueue(label: "com.xferro.repository.\(key)")
            }

            let queue = repositoryQueues[key]
            changeObserver
                .debounce(for: 1, scheduler: RunLoop.main)
                .sink { [weak self] in
                    guard let self else { return }
                    queue!.sync { [weak self] in
                        guard let self else { return }
                        guard let worktreeRepositoryURL = Worktree.worktreeRepositoryURL(originalRepository: repository) else { return }
                        let selectableItem = SelectableStatus(repository: repository)
                        guard let worktree = Worktree(of: selectableItem) else { fatalError(.impossible) }

                        let wipRepository = worktree.worktreeRepository
                        var wipHead: OpaquePointer?
                        var commit: OpaquePointer?
                        git_repository_head(&wipHead, wipRepository.pointer)
                        let peelResult = withUnsafeMutablePointer(to: &commit) { commitPtr in
                            git_reference_peel(commitPtr, wipHead, GIT_OBJECT_COMMIT)
                        }
                        guard peelResult == GIT_OK.rawValue else {
                            fatalError()
                        }

                        let statusEntries = repository.status().mustSucceed()
                        let wipWorktreePath = worktreeRepositoryURL.path
                        for statusEntry in statusEntries {
                            let originalRepoPath = gitDir.deletingLastPathComponent().path
                            for (oldPath, newPath) in getPaths(from: statusEntry) {
                                print("-------------------------")
                                print("oldPath: \(oldPath), newPath: \(newPath)")
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
                                wipRepository.add(path: newPath!).mustSucceed()
                            }
                        }

                        let signiture = Signature.default(wipRepository).mustSucceed().makeUnsafeSignature().mustSucceed()
                        defer { git_signature_free(signiture) }
                        let index = wipRepository.unsafeIndex().mustSucceed()
                        defer { git_index_free(index) }
                        let _ = wipRepository.commit(
                            index: index,
                            parentCommits: [commit],
                            message: "Wip commit",
                            signature: signiture
                        ).mustSucceed()
                        updateWipCommits(worktree: worktree)
                    }
                }
                .store(in: &onGitFolderChangeObservers)

            repsositoryFolderWatchers[key] = FolderWatcher(
                folder: gitDir.deletingLastPathComponent(),
                excludingPaths: [gitDir.path],
                onChangeObserver: changeObserver)

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
        guard userSelectedAnItem == false, currentSelectedItem == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
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

    func userTapped(item: any SelectableItem) {
        userSelectedAnItem = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
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
            print("Failed to create bookmark: \(error)")
        }

        folder.stopAccessingSecurityScopedResource()
        userDidSelectFolder(folder)
    }
    func deleteRepositoryButtonTapped(_ repository: Repository) {

    }

    private func wipCommits(of item: any SelectableItem, worktree: Worktree?) -> [SelectableWipCommit] {
        var wipWorktree: Worktree?
        if let worktree {
            wipWorktree = worktree
        } else {
            wipWorktree = Worktree(of: item)
        }

        guard let wipWorktree else { return [] }
        if let status = item as? SelectableStatus, case .noCommit = status.type {
            return [SelectableWipCommit(repository: wipWorktree.worktreeRepository, commit: wipWorktree.worktreeRepository.commit().mustSucceed())]
        }

        let branch = Worktree.checkoutOrCreateAndCheckoutBranchOfWorktreeIfNeeded(
            worktreeRepository: wipWorktree.worktreeRepository,
            branchName: Worktree.worktreeBranchName(item: item),
            initialCommit: item.oid
        )

        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: wipWorktree.worktreeRepository, root: branch.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableWipCommit(repository: wipWorktree.worktreeRepository, commit: commit))
            if commit.oid == item.oid {
                break
            }
        }
        return commits
    }

    func isCurrentBranch(_ branch: Branch, head: CommitsViewModel.Head, in repository: Repository) -> Bool {
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
