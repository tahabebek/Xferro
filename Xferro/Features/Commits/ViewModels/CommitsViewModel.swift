//
//  CommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Combine
import Foundation
import Observation

@Observable class CommitsViewModel {
    static let wipBranchPrefix = "_xferro_wip_commits_for_"
    static let wipWorktreeFolder = "wip_worktrees"

    struct CurrentWipCommits {
        let commits: [SelectableWipCommit]
        let title: String
    }

    var currentSelectedItem: SelectedItem? {
        didSet {
            if currentSelectedItem != nil {
                switch currentSelectedItem!.selectedItemType {
                case .regular(let type):
                    switch type {
                    case .stash:
                        currentWipCommits = CurrentWipCommits(commits: [], title: "Stashes don't have wip commits")
                    default:
                        let wipCommits = wipCommits(of: currentSelectedItem!.selectableItem)
                        let wipCommitTitle = "Wip commits of \(currentSelectedItem!.selectableItem.name)"
                        currentWipCommits = CurrentWipCommits(commits: wipCommits, title: wipCommitTitle)
                    }
                case .wip:
                    break
                }
            }
        }
    }

    var currentWipCommits: CurrentWipCommits = CurrentWipCommits(commits: [], title: "")
    var forceRefresh = UUID().uuidString
    private(set) var repositories: [Repository] = []
    private var gitFolderWatchers: [String: FolderWatcher] = [:]
    private var repsositoryFolderWatchers: [String: FolderWatcher] = [:]
    private let userDidSelectFolder: (URL) -> Void
    private var onGitFolderChangeObservers: Set<AnyCancellable> = []

    init(repositories: [Repository], userDidSelectFolder: @escaping (URL) -> Void) {
        self.userDidSelectFolder = userDidSelectFolder
        for repository in repositories {
            self.addRepository(repository)
        }
        setupInitialCurrentSelectedItem()
    }

    func addRepository(_ repository: Repository) {
        guard let gitDir = repository.gitDir else { fatalError() }
        repositories.append(repository)
        if gitFolderWatchers[gitDir.path] == nil {
            let changeObserver = PassthroughSubject<Void, Never>()
            changeObserver
                .debounce(for: 1, scheduler: RunLoop.main)
                .sink { [weak self] in
                    guard let self else { return }
                    setupInitialCurrentSelectedItem()
                    forceRefresh = UUID().uuidString
                }
                .store(in: &onGitFolderChangeObservers)

            gitFolderWatchers[gitDir.path] = FolderWatcher(
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

        let repositoryPath = gitDir.deletingLastPathComponent().path
        if repsositoryFolderWatchers[repositoryPath] == nil {
            let changeObserver = PassthroughSubject<Void, Never>()
            changeObserver
                .debounce(for: 1, scheduler: RunLoop.main)
                .sink { [weak self] in
                    guard let self else { return }
                    let statusEntries = repository.status().mustSucceed()
                    let url = DataManager.appDir.appendingPathComponent(Self.wipWorktreeFolder).appendingPathComponent(repositoryPath)
                    let head = try! HEAD(for: repository)
                    let branchName = Self.wipBranchPrefix + head.oid.description
                    guard let wipWorktree = getWorktreeIfExists(branchName, url: url) else { return }
                    let wipRepository = wipWorktree.0

                    var wipHead: OpaquePointer?
                    var commit: OpaquePointer?
                    git_repository_head(&wipHead, wipRepository.pointer)
                    let peelResult = withUnsafeMutablePointer(to: &commit) { commitPtr in
                        git_reference_peel(commitPtr, wipHead, GIT_OBJECT_COMMIT)
                    }
                    guard peelResult == GIT_OK.rawValue else {
                        fatalError()
                    }

                    for statusEntry in statusEntries {
                        let originalRepoPath = repositoryPath
                        let wipWorktreePath = DataManager.appDirPath + "/\(Self.wipWorktreeFolder)/" + repositoryPath

                        for (oldPath, newPath) in getPaths(from: statusEntry) {
                            let status = statusEntry.status
                            if status.contains(.indexNew) || status.contains(.workTreeNew) {
                                let content = try! Data(contentsOf: URL(filePath: originalRepoPath + "/" + newPath!))
                                try! FileManager.default.createDirectory(atPath: wipWorktreePath + "/" + URL(filePath: newPath!).deletingLastPathComponent().path, withIntermediateDirectories: true)
                                try! content.write(to: URL(fileURLWithPath: wipWorktreePath + "/" + newPath!))
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
                    forceRefresh = UUID().uuidString
                }
                .store(in: &onGitFolderChangeObservers)

            repsositoryFolderWatchers[repositoryPath] = FolderWatcher(
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
        if let firstRepo = repositories.first {
            if let head = try? HEAD(for: firstRepo) {
                switch head {
                case .branch(let branch):
                    self.currentSelectedItem = .init(selectedItemType: .regular(.status(SelectableStatus(repository: firstRepo, type: .branch(branch)))))
                case .tag(let tagReference):
                    self.currentSelectedItem = .init(selectedItemType: .regular(.status(SelectableStatus(repository: firstRepo, type: .tag(tagReference)))))
                case .reference(let reference):
                    if let tag = try? firstRepo.tag(reference.oid).get() {
                        self.currentSelectedItem = .init(selectedItemType: .regular(.status(SelectableStatus(repository: firstRepo, type: .tag(TagReference.annotated(tag.name, tag))))))
                    }
                    if let commit = try? firstRepo.commit(reference.oid).get() {
                        self.currentSelectedItem = .init(selectedItemType: .regular(.status(SelectableStatus(repository: firstRepo, type: .detached(commit)))))
                    }
                }
            }
        }
    }
    func userTapped(item: any SelectableItem) {
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
    func stashes(of repository: Repository) -> [SelectableStash] {
        var stashes = [SelectableStash]()

        try? repository.stashes().get().forEach { stash in
            stashes.append(SelectableStash(repository: repository, stash: stash))
        }
        return stashes
    }
    func branches(of repository: Repository) -> [Branch] {
        var branches: [Branch] = []
        let head = try? HEAD(for: repository)

        let branchIterator = BranchIterator(repo: repository, type: .local)
        
        while let branch = try? branchIterator.next()?.get() {
            if branch.name.hasPrefix(Self.wipBranchPrefix) { continue }
            if let head, isCurrentBranch(branch, head: head, in: repository) {
                branches.insert(branch, at: 0)
            } else {
                branches.append(branch)
            }
        }
        return branches
    }
    func detachedTag(of repository: Repository) -> SelectableDetachedTag? {
        if let head = try? HEAD(for: repository) {
            switch head {
            case .branch:
                return nil
            case .tag(let tagReference):
                return SelectableDetachedTag(repository: repository, tag: tagReference)
            case .reference(let reference):
                if let tag = try? repository.tag(reference.oid).get() {
                    return SelectableDetachedTag(repository: repository, tag: TagReference.annotated(tag.name, tag))
                }
            }
        }
        return nil
    }
    func detachedCommit(of repository: Repository) -> SelectableDetachedCommit? {
        if let head = try? HEAD(for: repository) {
            switch head {
            case .branch, .tag:
                return nil
            case .reference(let reference):
                if let commit = try? repository.commit(reference.oid).get() {
                    return SelectableDetachedCommit(repository: repository, commit: commit)
                }
            }
        }
        return nil
    }
    func tags(of repository: Repository) -> [SelectableTag] {
        var tags: [SelectableTag] = []

        try? repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
                tags.append(SelectableTag(repository: repository, tag: tag))
        }
        return tags
    }
    func commits(of branch: Branch, in repository: Repository, count: Int = 10) -> [SelectableCommit] {
        var commits: [SelectableCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: branch.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableCommit(repository: repository, branch: branch, commit: commit))
            counter += 1
        }
        return commits
    }
    func detachedCommits(of commitOID: OID, in repository: Repository, count: Int = 10) -> [SelectableDetachedCommit] {
        var commits: [SelectableDetachedCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: commitOID.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableDetachedCommit(repository: repository, commit: commit))
            counter += 1
        }
        return commits
    }
    func detachedCommits(of tag: SelectableTag, in repository: Repository, count: Int = 10) -> [SelectableDetachedCommit] {
        detachedCommits(of: tag.tag.oid, in: repository, count: count)
    }
    func historyCommits(of repository: Repository) -> [SelectableHistoryCommit] {
        fatalError()
    }
    func HEAD(for repository: Repository) throws -> CommitsViewModel.Head {
        let headRef = try repository.HEAD().get()

        let head: CommitsViewModel.Head =
        if let branchRef = headRef as? Branch {
            .branch(branchRef)
        } else if let tagRef = headRef as? TagReference {
            .tag(tagRef)
        } else if let reference = headRef as? Reference {
            .reference(reference)
        } else {
            fatalError()
        }
        return head
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
    private func wipCommits(of item: any SelectableItem) -> [SelectableWipCommit] {
        guard let wipWorktree = wipWorktree(for: item) else { return [] }
        let repository = wipWorktree.0
        let branch = wipWorktree.1
        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: repository, root: branch.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableWipCommit(repository: repository, commit: commit))
            if commit.oid == item.oid {
                break
            }
        }
        return commits
    }

    private func getWorktreeIfExists(_ branchName: String, url: URL) -> (Repository, Branch)? {
        if Repository.isGitRepository(url: url).mustSucceed() {
            let wipWorkTree = Repository.at(url).mustSucceed()
            if let branch = try? wipWorkTree.branch(named: branchName).get() {
                return (wipWorkTree, branch)
            }
            return nil
        }
        return nil
    }

    private func createWorktreeIfNeeded(repository: Repository, branchName: String, url: URL) {
        if !Repository.isGitRepository(url: url).mustSucceed() {
            repository.addWorkTree(
                name: branchName,
                path: url.path(percentEncoded: false))
            .mustSucceed()
        }
    }

    private func checkoutAndCreateIfNeeded(repository: Repository, branchName: String, oid: OID?, url: URL) -> (Repository, Branch)? {
        let wipWorkTree = Repository.at(url).mustSucceed()
        if let branch = try? repository.branch(named: branchName).get() {
            wipWorkTree.checkout(branch.longName, .init(strategy: .Force)).mustSucceed()
            return (wipWorkTree, branch)
        } else if let oid {
            let branch = wipWorkTree.createBranch(branchName, oid: oid, force: true).mustSucceed()
            wipWorkTree.checkout(branch.longName, .init(strategy: .Force)).mustSucceed()
            return (wipWorkTree, branch)
        }
        return nil
    }
    private func wipWorktree(for item: any SelectableItem) -> (Repository, Branch)? {
        let repository = item.repository
        guard let repoPath = repository.gitDir?.deletingLastPathComponent().path() else {
            return nil
        }
        let url = DataManager.appDir.appendingPathComponent("wip_worktrees").appendingPathComponent(repoPath)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        let head = try! HEAD(for: repository)

        switch item {
        case _ as SelectableStatus:
            let branchName = Self.wipBranchPrefix + head.oid.description
            createWorktreeIfNeeded(repository: repository, branchName: branchName, url: url)
            return checkoutAndCreateIfNeeded(repository: repository, branchName: branchName, oid: head.oid, url: url)
        case let commit as SelectableCommit:
            let branchName = Self.wipBranchPrefix + commit.oid.description
            if commit.oid == head.oid {
                createWorktreeIfNeeded(repository: repository, branchName: branchName, url: url)
                return checkoutAndCreateIfNeeded(repository: repository, branchName: branchName, oid: commit.oid, url: url)
            } else {
                return getWorktreeIfExists(branchName, url: url)
            }
        case let detachedCommit as SelectableDetachedCommit:
            let branchName = Self.wipBranchPrefix + detachedCommit.oid.description
            if detachedCommit.oid == head.oid {
                createWorktreeIfNeeded(repository: repository, branchName: branchName, url: url)
                return checkoutAndCreateIfNeeded(repository: repository, branchName: branchName, oid: detachedCommit.oid, url: url)
            } else {
                return getWorktreeIfExists(branchName, url: url)
            }
        case let detachedTag as SelectableDetachedTag:
            let branchName = Self.wipBranchPrefix + detachedTag.oid.description
            if detachedTag.oid == head.oid {
                createWorktreeIfNeeded(repository: repository, branchName: branchName, url: url)
                return checkoutAndCreateIfNeeded(repository: repository, branchName: branchName, oid: detachedTag.oid, url: url)
            } else {
                return getWorktreeIfExists(branchName, url: url)
            }
        case let tag as SelectableTag:
            let branchName = Self.wipBranchPrefix + tag.oid.description
            if tag.oid == head.oid {
                createWorktreeIfNeeded(repository: repository, branchName: branchName, url: url)
                return checkoutAndCreateIfNeeded(repository: repository, branchName: branchName, oid: tag.oid, url: url)
            } else {
                return getWorktreeIfExists(branchName, url: url)
            }
        case let historyCommit as SelectableHistoryCommit:
            let branchName = Self.wipBranchPrefix + historyCommit.oid.description
            if historyCommit.oid == head.oid {
                createWorktreeIfNeeded(repository: repository, branchName: branchName, url: url)
                return checkoutAndCreateIfNeeded(repository: repository, branchName: branchName, oid: historyCommit.oid, url: url)
            } else {
                return getWorktreeIfExists(branchName, url: url)
            }
        case _ as SelectableWipCommit:
            return nil
        default:
            fatalError()
        }
    }
}
