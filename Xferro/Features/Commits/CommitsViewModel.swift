//
//  CommitsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation
import Observation

@Observable class CommitsViewModel {
    struct RepositoryInfo: Identifiable, Codable {
        enum Head: Codable {
            case branch(Branch)
            case tag(TagReference)
            case reference(Reference)
        }
        var id: String { url.absoluteString }
        var branches: [Branch] = []
        var stashes: [Stash] = []
        var tags: [TagReference] = []
        var head: Head
        var url: URL
    }

    private(set) var repositories: [Repository] = []
    let userDidSelectFolder: (URL) -> Void

    init(repositories: [Repository], userDidSelectFolder: @escaping (URL) -> Void) {
        self.repositories = repositories
        self.userDidSelectFolder = userDidSelectFolder
    }

    func userTapped(repoIndex: UInt, branchIndex: UInt, commitIndex: UInt, wipCommiIndex: UInt?, fileIndex: UInt) {
    }
    func userTappedCurrentWork(repoIndex: UInt, branchIndex: UInt, wipCommitIndex: UInt?, fileIndex: UInt?) {
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

    func stashes(for repository: Repository) -> [Stash] {
        var stashes = [Stash]()

        try? repository.stashes().get().forEach { stash in
            stashes.append(stash)
        }
        return stashes
    }

    func branches(for repository: Repository) -> [Branch] {
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

    func tagReferences(for repository: Repository) -> [TagReference] {
        var tags: [TagReference] = []
        
        try? repository.allTags().get()
            .sorted { $0.name > $1.name }
            .forEach { tag in
            tags.append(tag)
        }
        return tags
    }

    func HEAD(for repository: Repository) throws -> RepositoryInfo.Head {
        let headRef = try repository.HEAD().get()

        let head: CommitsViewModel.RepositoryInfo.Head =
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

    func isCurrentBranch(_ branch: Branch, head: RepositoryInfo.Head, in repository: Repository) -> Bool {
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

    func commitsForBranch(_ branch: Branch, in repository: Repository, count: Int = 10) -> [Commit] {
        var commits: [Commit] = []
        
        let commitIterator = CommitIterator(repo: repository, root: branch.oid.oid)
        var counter = 0
        while counter < count, let commit = try? commitIterator.next()?.get() {
            commits.append(commit)
            counter += 1
        }
        return commits
    }
}

extension Repository {
    var repositoryInfo: CommitsViewModel.RepositoryInfo {
        var stashes = [Stash]()

        try? self.stashes().get().forEach { stash in
            stashes.append(stash)
        }

        let branchIterator = BranchIterator(repo: self, type: .local)

        var branches = [Branch]()
        while let branch = try? branchIterator.next()?.get() {
            branches.append(branch)
        }

        let headRef = try? self.HEAD().get()

        let head: CommitsViewModel.RepositoryInfo.Head =
        if let branchRef = headRef as? Branch {
            .branch(branchRef)
        } else if let tagRef = headRef as? TagReference {
            .tag(tagRef)
        } else if let reference = headRef as? Reference {
            .reference(reference)
        } else {
            fatalError()
        }

        let tags = self.allTags().mustSucceed()
        return CommitsViewModel.RepositoryInfo(
            branches: branches,
            stashes: stashes,
            tags: tags,
            head: head,
            url: self.gitDir!
        )
    }
}
