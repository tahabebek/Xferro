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
    var oid: OID { get }
    var repositoryId: String { get }
    var repositoryName: String { get }
    var repositoryGitDir: String { get }
}

struct SelectableStatus: SelectableItem, Identifiable {
    enum StatusType: Identifiable, Equatable {
        case branch(String, Branch)
        case tag(String, TagReference)
        case detached(String, Reference)

        var id: String {
            switch self {
            case .branch(let gitDir, let branch):
                gitDir +/ branch.id
            case .tag(let gitDir, let tag):
                gitDir +/ tag.id
            case .detached(let gitDir, let reference):
                gitDir +/ reference.oid.id
            }
        }

        static func == (lhs: StatusType, rhs: StatusType) -> Bool {
            return lhs.id == rhs.id
        }

        static func of(gitDir: String, head: Head) -> StatusType {
            switch head {
            case .branch(let branch, _):
                return .branch(gitDir, branch)
            case .tag(let tag, _):
                return .tag(gitDir, tag)
            case .reference(let reference, _):
                return .detached(gitDir, reference)
            }
        }
    }

    var id: String {
        let id = repositoryId +/ type.id
        return id
    }

    static func == (lhs: SelectableStatus, rhs: SelectableStatus) -> Bool {
        return lhs.id == rhs.id
    }

    var wipDescription: String {
        switch type {
        case .branch(_, let branch):
            "\"\(branch.name)\" branch of \(repositoryName)"
        case .tag(_, let tag):
            "\"\(tag.name)\" tag of \(repositoryName)"
        case .detached(_, let commit):
            "detached commit \"\(commit.oid.debugOID.prefix(4))\" of \(repositoryName)"
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

    let statusEntries: [StatusEntry]
    let type: StatusType
    let repositoryId: String
    let repositoryName: String
    let repositoryGitDir: String
    var timestamp: Date

    init(repositoryInfo: RepositoryInfo) {
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.type = StatusType.of(gitDir: repositoryInfo.repository.gitDir.path, head: repositoryInfo.head)
        self.statusEntries = repositoryInfo.status
        self.timestamp = Date()
    }

    init(
        repositoryName: String,
        repositoryId: String,
        repositoryGitDir: String,
        type: StatusType,
        statusEntries: [StatusEntry]
    ) {
        self.repositoryName = repositoryName
        self.repositoryId = repositoryId
        self.repositoryGitDir = repositoryGitDir
        self.type = type
        self.statusEntries = statusEntries
        self.timestamp = Date()
    }
}

struct SelectableCommit: SelectableItem, Identifiable, BranchItem {
    init(
        repositoryInfo: RepositoryInfo,
        branch: Branch,
        commit: Commit
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.branch = branch
        self.commit = commit
    }

    init(repositoryGitDir: String, repositoryName: String, repositoryId: String, branch: Branch, commit: Commit) {
        self.repositoryGitDir = repositoryGitDir
        self.repositoryName = repositoryName
        self.repositoryId = repositoryId
        self.branch = branch
        self.commit = commit
    }
    
    var id: String { repositoryId + branch.id + commit.id }
    static func == (lhs: SelectableCommit, rhs: SelectableCommit) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryGitDir: String
    let repositoryName: String
    let repositoryId: String
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "\"\(branch.name)\" branch of \(repositoryName)" }
    var oid: OID { commit.oid }
}

struct SelectableWipCommit: SelectableItem, Identifiable {
    var id: String { repositoryId + commit.id }
    static func == (lhs: SelectableWipCommit, rhs: SelectableWipCommit) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryGitDir: String
    let repositoryName: String
    let repositoryId: String
    let owner: any SelectableItem
    let branch: Branch
    let commit: Commit
    var wipDescription: String { owner.wipDescription }
    var oid: OID { commit.oid }

    init(
        repositoryInfo: RepositoryInfo,
        owner: any SelectableItem,
        branch: Branch,
        commit: Commit
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.owner = owner
        self.branch = branch
        self.commit = commit
    }

    init(
        repositoryGitDir: String,
        repositoryName: String,
        repositoryId: String,
        owner: any SelectableItem,
        branch: Branch,
        commit: Commit
    ) {
        self.repositoryGitDir = repositoryGitDir
        self.repositoryName = repositoryName
        self.repositoryId = repositoryId
        self.owner = owner
        self.branch = branch
        self.commit = commit
    }
}

struct SelectableDetachedCommit: SelectableItem, Identifiable, BranchItem {
    enum Owner: Equatable {
        case tag(TagReference)
        case commit(Commit)

        var name: String {
            switch self {
            case .tag(let tag): return "tag \(tag.name)"
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
    var id: String { repositoryId + commit.id }
    static func == (lhs: SelectableDetachedCommit, rhs: SelectableDetachedCommit) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryId: String
    let repositoryName: String
    let repositoryGitDir: String
    let commit: Commit
    let owner: Owner
    var wipDescription: String { "\"\(owner.name)\" of \(repositoryName)" }
    var oid: OID { commit.oid }

    init(
        repositoryInfo: RepositoryInfo,
        commit: Commit,
        owner: Owner
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.commit = commit
        self.owner = owner
    }

    init(repositoryId: String, repositoryName: String, repositoryGitDir: String, commit: Commit, owner: Owner) {
        self.repositoryId = repositoryId
        self.repositoryName = repositoryName
        self.repositoryGitDir = repositoryGitDir
        self.commit = commit
        self.owner = owner
    }
}

struct SelectableDetachedTag: SelectableItem, Identifiable {
    var id: String { repositoryId + tag.id }
    static func == (lhs: SelectableDetachedTag, rhs: SelectableDetachedTag) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryGitDir: String
    let repositoryName: String
    let repositoryId: String
    let tag: TagReference
    var wipDescription: String { "\"\(tag.name)\" tag of \(repositoryName)" }
    var oid: OID { tag.oid }

    init(
        repositoryInfo: RepositoryInfo,
        tag: TagReference
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.tag = tag
    }

    init(repositoryId: String, repositoryName: String, repositoryGitDir: String, tag: TagReference) {
        self.repositoryId = repositoryId
        self.repositoryName = repositoryName
        self.repositoryGitDir = repositoryGitDir
        self.tag = tag
    }
}

struct SelectableHistoryCommit: SelectableItem, Identifiable {
    var id: String { repositoryId + branch.id + commit.id }
    static func == (lhs: SelectableHistoryCommit, rhs: SelectableHistoryCommit) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryId: String
    let repositoryName: String
    let repositoryGitDir: String
    let branch: Branch
    let commit: Commit
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { commit.oid }

    init(
        repositoryInfo: RepositoryInfo,
        branch: Branch,
        commit: Commit
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.branch = branch
        self.commit = commit
    }
}

struct SelectableTag: SelectableItem, Identifiable {
    var id: String { repositoryId + tag.id }
    static func == (lhs: SelectableTag, rhs: SelectableTag) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryId: String
    let repositoryName: String
    let repositoryGitDir: String
    let tag: TagReference
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { tag.oid }

    init(
        repositoryInfo: RepositoryInfo,
        tag: TagReference
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.tag = tag
    }
}

struct SelectableStash: SelectableItem, Identifiable {
    var id: String { repositoryId + stash.id.formatted() }
    static func == (lhs: SelectableStash, rhs: SelectableStash) -> Bool {
        lhs.id == rhs.id
    }

    let repositoryGitDir: String
    let repositoryName: String
    let repositoryId: String
    let stash: Stash
    var wipDescription: String { fatalError(.unavailable) }
    var oid: OID { stash.oid }

    init(
        repositoryInfo: RepositoryInfo,
        stash: Stash
    ) {
        self.repositoryId = repositoryInfo.repository.idOfRepo
        self.repositoryName = repositoryInfo.repository.nameOfRepo
        self.repositoryGitDir = repositoryInfo.repository.gitDir.path
        self.stash = stash
    }
}

extension Repository {
    var idOfRepo: String {
        gitDir.deletingLastPathComponent().path
    }

    var nameOfRepo: String {
        gitDir.deletingLastPathComponent().lastPathComponent
    }
}
