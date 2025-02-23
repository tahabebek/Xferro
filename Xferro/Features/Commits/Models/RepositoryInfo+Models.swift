//
//  RepositoryInfo+Models.swift
//  Xferro
//
//  Created by Taha Bebek on 2/23/25.
//

import Foundation

extension RepositoryInfo {
    struct BranchInfo: Identifiable, Equatable {
        var id: String {
            branch.name + branch.commit.oid.description
        }
        let branch: Branch
        var commits: [SelectableCommit] = []
        let repository: Repository
        let head: Head
    }

    struct WipBranchInfo: Identifiable, Equatable {
        var id: String {
            branch.name + branch.commit.oid.description
        }
        let branch: Branch
        var commits: [SelectableWipCommit] = []
        let repository: Repository
        let head: Head
    }

    struct TagInfo: Identifiable, Equatable {
        var id: String {
            tag.id + commits.reduce(into: "") { result, commit in
                result += commit.id
            }
        }
        let tag: SelectableDetachedTag
        var commits: [SelectableDetachedCommit] = []
        let repository: Repository
        let head: Head
    }

    struct DetachedCommitInfo: Identifiable, Equatable {
        var id: String {
            detachedCommit.id + commits.reduce(into: "") { result, commit in
                result += commit.id
            }
        }
        var detachedCommit: SelectableDetachedCommit!
        var commits: [SelectableDetachedCommit] = []
        let repository: Repository
        let head: Head
    }

    enum ChangeType {
        case head(RepositoryInfo)
        case index(RepositoryInfo)
        case reflog(RepositoryInfo)
        case localBranches(RepositoryInfo)
        case remoteBranches(RepositoryInfo)
        case tags(RepositoryInfo)
        case stash(RepositoryInfo)
    }
}
