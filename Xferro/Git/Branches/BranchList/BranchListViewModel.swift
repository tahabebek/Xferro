//
//  BranchListViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation
import Observation

@Observable class BranchListViewModel {
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

    init(repositories: [Repository]) {
        self.repositories = repositories
    }

    func addRepositoryButtonTapped() {

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
        
        let branchIterator = BranchIterator(repo: repository, type: .local)
        
        while let branch = try? branchIterator.next()?.get() {
            branches.append(branch)
        }
        return branches
    }

    func tagReferences(for repository: Repository) -> [TagReference] {
        var tags: [TagReference] = []
        
        try? repository.allTags().get().forEach { tag in
            tags.append(tag)
        }
        return tags
    }

    func head(for repository: Repository) -> RepositoryInfo.Head {
        let headRef = try? repository.HEAD().get()

        let head: BranchListViewModel.RepositoryInfo.Head =
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

    func isCurrentBranch(_ branch: Branch, in repository: Repository) -> Bool {
        let head = head(for: repository)
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

    func commitsForBranch(_ branch: Branch, in repository: Repository, count: Int = 100) -> [Commit] {
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
    var repositoryInfo: BranchListViewModel.RepositoryInfo {
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

        let head: BranchListViewModel.RepositoryInfo.Head =
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
        return BranchListViewModel.RepositoryInfo(
            branches: branches,
            stashes: stashes,
            tags: tags,
            head: head,
            url: self.gitDir!
        )
    }
}
