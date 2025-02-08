//
//  CommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation
import Observation

protocol SelectableItem: Equatable, Identifiable {
    var name: String { get }
}

@Observable class CommitsViewModel {
    enum Head: Codable {
        case branch(Branch)
        case tag(TagReference)
        case reference(Reference)

        var oid: OID {
            switch self {
            case .branch(let branch):
                return branch.oid
            case .tag(let tagReference):
                return tagReference.oid
            case .reference(let reference):
                return reference.oid
            }
        }
    }

    struct SelectedItem: Equatable {
        let selectedItemType: SelectedItemType

        var repository: Repository {
            switch selectedItemType {
            case .regular(let regularSelectedItem):
                regularSelectedItem.repository
            case .wip(let wipSelectedItem):
                wipSelectedItem.repository
            }
        }

        var selectableItem: any SelectableItem {
            switch selectedItemType {
            case .regular(let regularSelectedItem):
                regularSelectedItem.selectableItem
            case .wip(let wipSelectedItem):
                wipSelectedItem.selectableItem
            }
        }

        enum SelectedItemType: Equatable {
            case regular(RegularSelectedItem)
            case wip(WipSelectedItem)
        }

        enum WipSelectedItem: Equatable {
            case wipCommit(SelectableWipCommit)

            var repository: Repository {
                switch self {
                case .wipCommit(let selectableWipCommit):
                    selectableWipCommit.repository
                }
            }
            var selectableItem: any SelectableItem {
                switch self {
                case .wipCommit(let selectableWipCommit):
                    selectableWipCommit
                }
            }
        }
        enum RegularSelectedItem: Equatable {
            case status(SelectableStatus)
            case commit(SelectableCommit)
            case historyCommit(SelectableHistoryCommit)
            case detachedCommit(SelectableDetachedCommit)
            case detachedTag(SelectableDetachedTag)
            case tag(SelectableTag)
            case stash(SelectableStash)

            var repository: Repository {
                switch self {
                case .status(let selectableStatus):
                    selectableStatus.repository
                case .commit(let selectableCommit):
                    selectableCommit.repository
                case .historyCommit(let selectableHistoryCommit):
                    selectableHistoryCommit.repository
                case .detachedCommit(let selectableDetachedCommit):
                    selectableDetachedCommit.repository
                case .detachedTag(let selectableDetachedTag):
                    selectableDetachedTag.repository
                case .tag(let selectableTag):
                    selectableTag.repository
                case .stash(let selectableStash):
                    selectableStash.repository
                }
            }

            var selectableItem: any SelectableItem {
                switch self {
                case .status(let selectableStatus):
                    selectableStatus
                case .commit(let selectableCommit):
                    selectableCommit
                case .historyCommit(let selectableHistoryCommit):
                    selectableHistoryCommit
                case .detachedCommit(let selectableDetachedCommit):
                    selectableDetachedCommit
                case .detachedTag(let selectableDetachedTag):
                    selectableDetachedTag
                case .tag(let selectableTag):
                    selectableTag
                case .stash(let selectableStash):
                    selectableStash
                }
            }
        }
    }

    struct SelectableStatus: SelectableItem, Identifiable {
        enum StatusType: Identifiable, Equatable {
            case branch(Branch)
            case tag(TagReference)
            case detached(Commit)

            var id: String {
                switch self {
                case .branch(let branch):
                    return branch.id
                case .tag(let tag):
                    return tag.id
                case .detached(let commit):
                    return commit.id
                }
            }

            static func == (lhs: StatusType, rhs: StatusType) -> Bool {
                switch (lhs, rhs) {
                case (.branch(let lhs), .branch(let rhs)):
                    return lhs == rhs
                case (.tag(let lhs), .tag(let rhs)):
                    return lhs == rhs
                case (.detached(let lhs), .detached(let rhs)):
                    return lhs == rhs
                default:
                    return false
                }
            }
        }

        var id: String {
            CommitsViewModel.idOfRepo(repository) + type.id
        }

        var name: String {
            switch type {
            case .branch(let branch):
                return "the current status of branch '\(branch.name)' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
            case .tag(let tag):
                return "the current status of tag '\(tag.name)' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
            case .detached(let commit):
                return "the current status of detached commit '\(commit.oid.description)' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
            }
        }
        let repository: Repository
        let type: StatusType
    }

    struct SelectableCommit: SelectableItem, Identifiable, BranchItem {
        var id: String { CommitsViewModel.idOfRepo(repository) + branch.id + commit.id }
        let repository: Repository
        let branch: Branch
        let commit: Commit
        var name: String { "commit '\(commit.oid.description)'" }
    }

    struct SelectableWipCommit: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + commit.id }
        let repository: Repository
        let commit: Commit
        var name: String { "commit '\(commit.oid.description)'" }
    }

    struct SelectableDetachedCommit: SelectableItem, Identifiable, BranchItem {
        var id: String { CommitsViewModel.idOfRepo(repository) + commit.id }
        let repository: Repository
        let commit: Commit
        var name: String { "commit '\(commit.oid.description)'" }
    }

    struct SelectableDetachedTag: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + tag.id }
        let repository: Repository
        let tag: TagReference
        var name: String { "tag '\(tag.name)'" }
    }

    struct SelectableHistoryCommit: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + branch.id + commit.id }
        let repository: Repository
        let branch: Branch
        let commit: Commit
        var name: String { "commit '\(commit.oid.description)'" }
    }

    struct SelectableTag: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + tag.id }
        let repository: Repository
        let tag: TagReference
        var name: String { "tag '\(tag.name)'" }
    }

    struct SelectableStash: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + stash.id.formatted() }
        let repository: Repository
        let stash: Stash
        var name: String { "stash '\(stash.oid.description)'" }
    }

    var currentSelectedItem: SelectedItem? {
        didSet {
            if currentSelectedItem != nil {
                switch currentSelectedItem!.selectedItemType {
                case .regular:
                    wipCommits = wipCommits(of: currentSelectedItem!.selectableItem)
                    wipCommitTitle = "WIP commits of \(currentSelectedItem!.selectableItem.name)"
                case .wip:
                    break
                }
            }
        }
    }

    var wipCommits: [SelectableWipCommit] = []
    var wipCommitTitle: String = ""
    var repositories: [Repository] = []
    
    private let userDidSelectFolder: (URL) -> Void

    init(repositories: [Repository], userDidSelectFolder: @escaping (URL) -> Void) {
        self.repositories = repositories
        self.userDidSelectFolder = userDidSelectFolder

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
        let wipRepository = wipRepository(for: item)
        var head = try? HEAD(for: wipRepository)
        if head == nil {
            do {
                _ = wipRepository.createBranch("master", force: true)
                _ = wipRepository.add(path: ".")
                let signiture: Signature? = nil
                let _ = wipRepository.commit(message: "Initial commit", signature: signiture)
                head = try HEAD(for: wipRepository)
            } catch {
                print(error.localizedDescription)
            }
        }

        var commits: [SelectableWipCommit] = []

        let commitIterator = CommitIterator(repo: wipRepository, root: head!.oid.oid)
        while let commit = try? commitIterator.next()?.get() {
            commits.append(SelectableWipCommit(repository: wipRepository, commit: commit))
        }
        return commits
    }

    private func wipRepository(for item: any SelectableItem) -> Repository {
        let appDir = DataManager.appDir
        try? FileManager.default.createDirectory(
            at: appDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let url = URL(fileURLWithPath: appDir.path()).appendingPathComponent("wip\(item.id)")
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil
        )
        if !Repository.isGitRepository(url: url).mustSucceed() {
            let wipRepository = Repository.create(at: url).mustSucceed()
            return wipRepository
        }
        return Repository.at(url).mustSucceed()
    }

    private static func idOfRepo(_ repository: Repository) -> String {
        repository.gitDir?.deletingLastPathComponent().path ?? ""
    }
    private static func nameOfRepo(_ repository: Repository) -> String {
        repository.gitDir?.deletingLastPathComponent().lastPathComponent ?? ""
    }
}
