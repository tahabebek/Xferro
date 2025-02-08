//
//  CommitsViewModel+SelectableItem.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

protocol SelectableItem: Equatable, Identifiable {
    var id: String { get }
    var name: String { get }
    var repository: Repository { get }
    var oid: OID { get }
}

extension CommitsViewModel {
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
            CommitsViewModel.idOfRepo(repository) + "/" + type.id
        }

        var name: String {
            switch type {
            case .branch(let branch):
                return "'\(branch.commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
            case .tag(let tag):
                return "'\(tag.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
            case .detached(let commit):
                return "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'"
            }
        }

        var oid: OID {
            switch type {
            case .branch(let branch):
                return branch.commit.oid
            case .tag(let tag):
                return tag.oid
            case .detached(let commit):
                return commit.oid
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
        var name: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { commit.oid }
    }

    struct SelectableWipCommit: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + commit.id }
        let repository: Repository
        let commit: Commit
        var name: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { commit.oid }
    }

    struct SelectableDetachedCommit: SelectableItem, Identifiable, BranchItem {
        var id: String { CommitsViewModel.idOfRepo(repository) + commit.id }
        let repository: Repository
        let commit: Commit
        var name: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { commit.oid }
    }

    struct SelectableDetachedTag: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + tag.id }
        let repository: Repository
        let tag: TagReference
        var name: String { "'\(tag.name)' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { tag.oid }
    }

    struct SelectableHistoryCommit: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + branch.id + commit.id }
        let repository: Repository
        let branch: Branch
        let commit: Commit
        var name: String { "'\(commit.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { commit.oid }
    }

    struct SelectableTag: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + tag.id }
        let repository: Repository
        let tag: TagReference
        var name: String { "'\(tag.name)' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { tag.oid }
    }

    struct SelectableStash: SelectableItem, Identifiable {
        var id: String { CommitsViewModel.idOfRepo(repository) + stash.id.formatted() }
        let repository: Repository
        let stash: Stash
        var name: String { "'\(stash.oid.debugOID.prefix(4))' in repository '\(CommitsViewModel.nameOfRepo(repository))'" }
        var oid: OID { stash.oid }
    }

    private static func idOfRepo(_ repository: Repository) -> String {
        repository.gitDir?.deletingLastPathComponent().path ?? ""
    }
    
    private static func nameOfRepo(_ repository: Repository) -> String {
        repository.gitDir?.deletingLastPathComponent().lastPathComponent ?? ""
    }
}
