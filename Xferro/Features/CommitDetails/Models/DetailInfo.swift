//
//  DetailInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Foundation

struct DetailInfo {
    enum DetailType {
        case empty
        case status(SelectableStatus, [StatusEntry])
        case commit(SelectableCommit)
        case wipCommit(SelectableWipCommit, WipWorktree)
        case detachedCommit(SelectableDetachedCommit)
        case historyCommit(SelectableHistoryCommit)
        case tag(SelectableTag)
        case detachedTag(SelectableDetachedTag)
        case stash(SelectableStash)

        var title: String {
            switch self {
            case .empty:
                "Empty"
            case .commit(let commit):
                "Commit \(commit.wipDescription)"
            case .wipCommit(let commit, _):
                "Wip commit '\(commit.oid.debugOID.prefix(2))' of '\(commit.repository.gitDir.deletingLastPathComponent().lastPathComponent)''"
            case .detachedCommit(let commit):
                "Detached commit \(commit.wipDescription)"
            case .historyCommit(let commit):
                "History commit \(commit.wipDescription)"
            case .tag(let tag):
                "Tag \(tag.wipDescription)"
            case .detachedTag(let tag):
                "Detached Tag \(tag.wipDescription)"
            case .status(let status, _):
                "Status of \(status.wipDescription)"
            case .stash(let stash):
                "Commit \(stash.wipDescription)"
            }
        }
    }

    let type: DetailType
}
