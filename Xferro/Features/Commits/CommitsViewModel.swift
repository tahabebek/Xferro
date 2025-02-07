//
//  CommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation
import Observation

protocol SelectableItem: Equatable, Identifiable {}

@Observable class CommitsViewModel {
    enum Head: Codable {
        case branch(Branch)
        case tag(TagReference)
        case reference(Reference)
    }

    enum SelectedItem {
        case status(SelectableStatus)
        case commit(SelectableCommit)
        case wipCommit(SelectableWipCommit)
        case historyCommit(SelectableHistoryCommit)
        case detachedCommit(SelectableDetachedCommit)
        case tag(SelectableTag)
        case stash(SelectableStash)
    }

    struct SelectableStatus: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + branch.id }
        let repository: Repository
        let branch: Branch
    }

    struct SelectableCommit: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + branch.id + commit.id }
        let repository: Repository
        let branch: Branch
        let commit: Commit
    }

    struct SelectableWipCommit: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + branch.id + wip.id }
        let repository: Repository
        let branch: Branch
        let wip: Commit
    }

    struct SelectableDetachedCommit: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + commit.id }
        let repository: Repository
        let commit: Commit
    }

    struct SelectableHistoryCommit: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + branch.id + commit.id }
        let repository: Repository
        let branch: Branch
        let commit: Commit
    }

    struct SelectableTag: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + tag.id }
        let repository: Repository
        let tag: TagReference
    }

    struct SelectableStash: SelectableItem, Identifiable {
        var id: String { repository.id.hashValue.formatted() + stash.id.formatted() }
        let repository: Repository
        let stash: Stash
    }

    var currentSelectedItem: SelectedItem?
    var repositories: [Repository] = []
    
    private let userDidSelectFolder: (URL) -> Void

    init(repositories: [Repository], userDidSelectFolder: @escaping (URL) -> Void) {
        self.repositories = repositories
        self.userDidSelectFolder = userDidSelectFolder

        if let firstRepo = repositories.first {
            if let head = try? HEAD(for: firstRepo) {
                switch head {
                case .branch(let branch):
                    self.currentSelectedItem = .status(SelectableStatus(repository: firstRepo, branch: branch))
                case .tag(let tagReference):
                    self.currentSelectedItem = .tag(SelectableTag(repository: firstRepo, tag: tagReference))
                case .reference(let reference):
                    if let commit = try? firstRepo.commit(reference.oid).get() {
                        self.currentSelectedItem = .detachedCommit(SelectableDetachedCommit(repository: firstRepo, commit: commit))
                    }
                }
            }
        }
    }

    func userTapped(item: any SelectableItem) {
        switch item {
        case let status as SelectableStatus:
            currentSelectedItem = .status(status)
        case let commit as SelectableCommit:
            currentSelectedItem = .commit(commit)
        case let wipCommit as SelectableWipCommit:
            currentSelectedItem = .wipCommit(wipCommit)
        case let historyCommit as SelectableHistoryCommit:
            currentSelectedItem = .historyCommit(historyCommit)
        case let tag as SelectableTag:
            currentSelectedItem = .tag(tag)
        case let stash as SelectableStash:
            currentSelectedItem = .stash(stash)
        default:
            fatalError()
        }
    }

    func isSelected(item: any SelectableItem) -> Bool {
        switch item {
        case let status as SelectableStatus:
            if case .status(let currentStatus) = currentSelectedItem {
                return status == currentStatus
            } else {
                return false
            }
        case let commit as SelectableCommit:
            if case .commit(let currentCommit) = currentSelectedItem {
                return commit == currentCommit
            } else {
                return false
            }
        case let wipCommit as SelectableWipCommit:
            if case .wipCommit(let currentWipCommit) = currentSelectedItem {
                return wipCommit == currentWipCommit
            } else {
                return false
            }
        case let historyCommit as SelectableHistoryCommit:
            if case .historyCommit(let currentHistoryCommit) = currentSelectedItem {
                return historyCommit == currentHistoryCommit
            } else {
                return false
            }
        case let tag as SelectableTag:
            if case .tag(let currentTag) = currentSelectedItem {
                return tag == currentTag
            } else {
                return false
            }
        case let stash as SelectableStash:
            if case .stash(let currentStash) = currentSelectedItem {
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
            if let head, isCurrentBranch(branch, head: head, in: repository) {
                branches.insert(branch, at: 0)
            } else {
                branches.append(branch)
            }
        }
        return branches
    }

    func detachedTag(of repository: Repository) -> SelectableTag {
        fatalError()
    }

    func detachedCommit(of repository: Repository) -> SelectableCommit {
        fatalError()
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

    func wipCommits(of branch: Branch, in repository: Repository) -> [SelectableWipCommit] {
        fatalError()
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

    private func setupWipRepository(for repository: Repository, commit: Commit) {
        let url = wipURL(for: repository, commit: commit)
        print(url)
    }

    private func wipURL(for repository: Repository, commit: Commit) -> URL {
        let appDir = DataManager.appDir
        try? FileManager.default.createDirectory(
            at: appDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        print(appDir)
        return URL(fileURLWithPath: appDir.path()).appendingPathComponent("wip\(repository.gitDir!.deletingLastPathComponent().path)/\(commit.oid.description)")
    }
}
