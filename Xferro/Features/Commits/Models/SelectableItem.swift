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
    var repositoryInfo: RepositoryInfo { get }
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
        case branch(RepositoryInfo, Branch)
        case tag(RepositoryInfo, TagReference)
        case detached(RepositoryInfo, Commit)

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

        static func of(_ repositoryInfo: RepositoryInfo) -> StatusType {
            switch repositoryInfo.head {
            case .branch(let branch):
                return .branch(repositoryInfo, branch)
            case .tag(let tag):
                return .tag(repositoryInfo, tag)
            case .reference(let reference):
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
            return "'\(branch.name)' in '\(repository.nameOfRepo)'"
        case .tag(_, let tag):
            return "'\(tag.name)' in '\(repository.nameOfRepo)'"
        case .detached(_, let commit):
            return "'\(commit.oid.debugOID.prefix(4))' in '\(repository.nameOfRepo)'"
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

    let repositoryInfo: RepositoryInfo
    let type: StatusType

    init(repositoryInfo: RepositoryInfo) {
        self.repositoryInfo = repositoryInfo
        self.type = StatusType.of(repositoryInfo)
    }
}

struct SelectableCommit: SelectableItem, Identifiable, BranchItem {
    init(repositoryInfo: RepositoryInfo, branch: Branch, commit: Commit) {
        self.repositoryInfo = repositoryInfo
        self.branch = branch
        self.commit = commit
    }
    var id: String { repository.idOfRepo + branch.id + commit.id }
    let repositoryInfo: RepositoryInfo
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "'\(branch.name)' in '\(repository.nameOfRepo)'" }
    var oid: OID { commit.oid }
}

struct SelectableWipCommit: SelectableItem, Identifiable {
    var id: String { repository.gitDir.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent + commit.id }
    let repositoryInfo: RepositoryInfo
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
            case .tag(let tag): return tag.name
            case .commit(let commit): return commit.oid.debugOID
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
    let repositoryInfo: RepositoryInfo
    let commit: Commit
    let owner: Owner
    var wipDescription: String { "'\(owner.name)' in '\(repository.nameOfRepo)'" }
    var oid: OID { commit.oid }

    init(repositoryInfo: RepositoryInfo, commit: Commit, owner: Owner) {
        self.repositoryInfo = repositoryInfo
        self.commit = commit
        self.owner = owner
    }
}

struct SelectableDetachedTag: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + tag.id }
    let repositoryInfo: RepositoryInfo
    let tag: TagReference
    var wipDescription: String { "'\(tag.name)' in '\(repository.nameOfRepo)'" }
    var oid: OID { tag.oid }
}

struct SelectableHistoryCommit: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + branch.id + commit.id }
    let repositoryInfo: RepositoryInfo
    let branch: Branch
    let commit: Commit
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { commit.oid }
}

struct SelectableTag: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + tag.id }
    let repositoryInfo: RepositoryInfo
    let tag: TagReference
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { tag.oid }
}

struct SelectableStash: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + stash.id.formatted() }
    let repositoryInfo: RepositoryInfo
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
