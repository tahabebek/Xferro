//
//  CommitsViewModel+SelectableItem.swift
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
        case noCommit(Repository)

        var id: String {
            guard let repoDir = repository.gitDir?.path else { fatalError(.invalid) }
            switch self {
            case .branch(_, let branch):
                return repoDir + branch.id
            case .tag(_, let tag):
                return repoDir + tag.id
            case .detached(_, let commit):
                return repoDir + commit.id
            case .noCommit:
                return repoDir
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
            case .noCommit(let repository):
                repository
            }
        }

        static func == (lhs: StatusType, rhs: StatusType) -> Bool {
            lhs.id == rhs.id
        }

        static func withRepository(_ repository: Repository) -> StatusType {
            if let head = CommitsViewModel.HEAD(for: repository) {
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
            } else {
                return .noCommit(repository)
            }
        }
    }

    var id: String {
        CommitsViewModel.idOfRepo(repository) + "/" + type.id
    }

    var wipDescription: String {
        switch type {
        case .branch(_, let branch):
            return "'\(branch.commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
        case .tag(_, let tag):
            return "'\(tag.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
        case .detached(_, let commit):
            return "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
        case .noCommit:
            return "repository '\(CommitsViewModel.nameOfRepo(repository))'"
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
        case .noCommit:
            fatalError(.unavailable)
        }
    }

    let repository: Repository
    let type: StatusType

    init(repository: Repository) {
        self.repository = repository
        self.type = StatusType.withRepository(repository)
    }
}

struct SelectableCommit: SelectableItem, Identifiable, BranchItem {
    var id: String { CommitsViewModel.idOfRepo(repository) + branch.id + commit.id }
    let repository: Repository
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { commit.oid }
}

struct SelectableWipCommit: SelectableItem, Identifiable {
    var id: String { CommitsViewModel.idOfRepo(repository) + commit.id }
    let repository: Repository
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { commit.oid }
}

struct SelectableDetachedCommit: SelectableItem, Identifiable, BranchItem {
    var id: String { CommitsViewModel.idOfRepo(repository) + commit.id }
    let repository: Repository
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { commit.oid }
}

struct SelectableDetachedTag: SelectableItem, Identifiable {
    var id: String { CommitsViewModel.idOfRepo(repository) + tag.id }
    let repository: Repository
    let tag: TagReference
    var wipDescription: String { "'\(tag.name)' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { tag.oid }
}

struct SelectableHistoryCommit: SelectableItem, Identifiable {
    var id: String { CommitsViewModel.idOfRepo(repository) + branch.id + commit.id }
    let repository: Repository
    let branch: Branch
    let commit: Commit
    var wipDescription: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { commit.oid }
}

struct SelectableTag: SelectableItem, Identifiable {
    var id: String { CommitsViewModel.idOfRepo(repository) + tag.id }
    let repository: Repository
    let tag: TagReference
    var wipDescription: String { "'\(tag.name)' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { tag.oid }
}

struct SelectableStash: SelectableItem, Identifiable {
    var id: String { CommitsViewModel.idOfRepo(repository) + stash.id.formatted() }
    let repository: Repository
    let stash: Stash
    var wipDescription: String { "'\(stash.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
    var oid: OID { stash.oid }
}

extension CommitsViewModel {
    static func idOfRepo(_ repository: Repository) -> String {
        repository.gitDir?.deletingLastPathComponent().path ?? ""
    }

    static func nameOfRepo(_ repository: Repository) -> String {
        repository.gitDir?.deletingLastPathComponent().lastPathComponent ?? ""
    }
}
