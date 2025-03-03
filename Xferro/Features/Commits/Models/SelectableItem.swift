//
//  SelectableItem.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

protocol SelectableItem: Equatable, Identifiable {
    var id: String { get }
    var wipDescription: String { get }
    var repositoryInfo: RepositoryViewModel { get }
    var oid: OID { get }
    var repository: Repository { get }
    var head: Head { get }
}

extension SelectableItem {
    var repository: Repository {
        repositoryInfo.repository
    }

    var head: Head {
        repositoryInfo.head
    }
}

struct SelectableStatus: SelectableItem, Identifiable {
    enum StatusType: Identifiable, Equatable {
        case branch(RepositoryViewModel, Branch)
        case tag(RepositoryViewModel, TagReference)
        case detached(RepositoryViewModel, Commit)

        var id: String {
            let repoDir = repository.gitDir.path
            switch self {
            case .branch(_, let branch):
                return repoDir + branch.id
            case .tag(_, let tag):
                return repoDir + tag.id
            case .detached(_, let commit):
                return repoDir + commit.id
            }
        }

        var repository: Repository {
            switch self {
            case .branch(let repositoryInfo, _):
                repositoryInfo.repository
            case .tag(let repositoryInfo, _):
                repositoryInfo.repository
            case .detached(let repositoryInfo, _):
                repositoryInfo.repository
            }
        }

        static func == (lhs: StatusType, rhs: StatusType) -> Bool {
            lhs.id == rhs.id
        }

        static func of(_ repositoryInfo: RepositoryViewModel) -> StatusType {
            switch repositoryInfo.head {
            case .branch(let branch, _):
                return .branch(repositoryInfo, branch)
            case .tag(let tag, _):
                return .tag(repositoryInfo, tag)
            case .reference(let reference, _):
                if let tag = try? repositoryInfo.repository.tag(reference.oid).get() {
                    return .tag(repositoryInfo, TagReference.annotated(tag.name, tag))
                }
                else if let commit = try? repositoryInfo.repository.commit(reference.oid).get() {
                    return .detached(repositoryInfo, commit)
                } else {
                    fatalError(.impossible)
                }
            }
        }
    }

    var id: String {
        repository.idOfRepo + "/" + type.id
    }

    var wipDescription: String {
        switch type {
        case .branch(_, let branch):
            "Branch \(branch.name) of \(repository.nameOfRepo)"
        case .tag(_, let tag):
            "Tag \(tag.name) of \(repository.nameOfRepo)"
        case .detached(_, let commit):
            "Detached commit \(commit.oid.debugOID.prefix(4)) of \(repository.nameOfRepo)"
        }
    }

    var oid: OID {
        switch type {
        case .branch(_, let branch):
            return branch.commit.oid
        case .tag(_, let tag):
            return tag.oid
        case .detached(_, let commit):
            return commit.oid
        }
    }

    var statusEntries: [StatusEntry] {
        repositoryInfo.status
    }

    let repositoryInfo: RepositoryViewModel
    let type: StatusType

    init(repositoryInfo: RepositoryViewModel) {
        self.repositoryInfo = repositoryInfo
        self.type = StatusType.of(repositoryInfo)
    }
}

struct SelectableCommit: SelectableItem, Identifiable, BranchItem {
    init(repositoryInfo: RepositoryViewModel, branch: Branch, commit: Commit) {
        self.repositoryInfo = repositoryInfo
        self.branch = branch
        self.commit = commit
    }
    var id: String { repository.idOfRepo + branch.id + commit.id }
    let repositoryInfo: RepositoryViewModel
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "Branch \(branch.name) of \(repository.nameOfRepo)" }
    var oid: OID { commit.oid }
}

struct SelectableWipCommit: SelectableItem, Identifiable {
    var id: String { repository.gitDir.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent + commit.id }
    let repositoryInfo: RepositoryViewModel
    let branch: Branch
    let commit: Commit
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { commit.oid }
}

struct SelectableDetachedCommit: SelectableItem, Identifiable, BranchItem {
    enum Owner: Equatable {
        case tag(TagReference)
        case commit(Commit)

        var name: String {
            switch self {
            case .tag(let tag): return "Tag \(tag.name)"
            case .commit(let commit): return "Detached commit \(commit.oid.debugOID)"
            }
        }

        var oid: OID {
            switch self {
            case .tag(let tag): return tag.oid
            case .commit(let commit): return commit.oid
            }
        }
    }
    var id: String { repository.idOfRepo + commit.id }
    let repositoryInfo: RepositoryViewModel
    let commit: Commit
    let owner: Owner
    var wipDescription: String { "\(owner.name) of \(repository.nameOfRepo)" }
    var oid: OID { commit.oid }

    init(repositoryInfo: RepositoryViewModel, commit: Commit, owner: Owner) {
        self.repositoryInfo = repositoryInfo
        self.commit = commit
        self.owner = owner
    }
}

struct SelectableDetachedTag: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + tag.id }
    let repositoryInfo: RepositoryViewModel
    let tag: TagReference
    var wipDescription: String { "Tag \(tag.name) of \(repository.nameOfRepo)" }
    var oid: OID { tag.oid }
}

struct SelectableHistoryCommit: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + branch.id + commit.id }
    let repositoryInfo: RepositoryViewModel
    let branch: Branch
    let commit: Commit
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { commit.oid }
}

struct SelectableTag: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + tag.id }
    let repositoryInfo: RepositoryViewModel
    let tag: TagReference
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { tag.oid }
}

struct SelectableStash: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + stash.id.formatted() }
    let repositoryInfo: RepositoryViewModel
    let stash: Stash
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { stash.oid }
}

extension Repository {
    var idOfRepo: String {
        gitDir.deletingLastPathComponent().path
    }

    var nameOfRepo: String {
        gitDir.deletingLastPathComponent().lastPathComponent
    }
}
