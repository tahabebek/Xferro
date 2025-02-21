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
    var repository: Repository { get }
    var oid: OID { get }
}

struct SelectableStatus: SelectableItem, Identifiable {
    enum StatusType: Identifiable, Equatable {
        case branch(Repository, Branch)
        case tag(Repository, TagReference)
        case detached(Repository, Commit)

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
            case .branch(let repository, _):
                repository
            case .tag(let repository, _):
                repository
            case .detached(let repository, _):
                repository
            }
        }

        static func == (lhs: StatusType, rhs: StatusType) -> Bool {
            lhs.id == rhs.id
        }

        static func of(_ repository: Repository, head: Head) -> StatusType {
            switch head {
            case .branch(let branch):
                return .branch(repository, branch)
            case .tag(let tag):
                return .tag(repository, tag)
            case .reference(let reference):
                if let tag = try? repository.tag(reference.oid).get() {
                    return .tag(repository, TagReference.annotated(tag.name, tag))
                }
                else if let commit = try? repository.commit(reference.oid).get() {
                    return .detached(repository, commit)
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
            return "'\(branch.commit.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'"
        case .tag(_, let tag):
            return "'\(tag.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'"
        case .detached(_, let commit):
            return "'\(commit.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'"
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

    let repository: Repository
    let type: StatusType

    init(repository: Repository, head: Head) {
        self.repository = repository
        self.type = StatusType.of(repository, head: head)
    }
}

struct SelectableCommit: SelectableItem, Identifiable, BranchItem {
    init(repository: Repository, branch: Branch, commit: Commit) {
        self.repository = repository
        self.branch = branch
        self.commit = commit
    }
    var id: String { repository.idOfRepo + branch.id + commit.id }
    let repository: Repository
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'" }
    var oid: OID { commit.oid }
}

struct SelectableWipCommit: SelectableItem, Identifiable {
    var id: String { repository.gitDir.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent + commit.id }
    let repository: Repository
    let commit: Commit
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { commit.oid }
}

struct SelectableDetachedCommit: SelectableItem, Identifiable, BranchItem {
    var id: String { repository.idOfRepo + commit.id }
    let repository: Repository
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'" }
    var oid: OID { commit.oid }
}

struct SelectableDetachedTag: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + tag.id }
    let repository: Repository
    let tag: TagReference
    var wipDescription: String { "'\(tag.name)' in repository '\(repository.nameOfRepo)'" }
    var oid: OID { tag.oid }
}

struct SelectableHistoryCommit: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + branch.id + commit.id }
    let repository: Repository
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'" }
    var oid: OID { commit.oid }
}

struct SelectableTag: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + tag.id }
    let repository: Repository
    let tag: TagReference
    var wipDescription: String { "'\(tag.name)' in repository '\(repository.nameOfRepo)'" }
    var oid: OID { tag.oid }
}

struct SelectableStash: SelectableItem, Identifiable {
    var id: String { repository.idOfRepo + stash.id.formatted() }
    let repository: Repository
    let stash: Stash
    var wipDescription: String { "'\(stash.oid.debugOID.prefix(4))' in repository '\(repository.nameOfRepo)'" }
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
