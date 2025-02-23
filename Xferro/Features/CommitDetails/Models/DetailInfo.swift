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
        case status(SelectableStatus)
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
                "Select a commit"
            case .commit(let commit):
                commit.repository.nameOfRepo
            case .wipCommit(let commit, _):
                commit.repository.nameOfRepo
            case .detachedCommit(let commit):
                commit.repository.nameOfRepo
            case .historyCommit(let commit):
                commit.repository.nameOfRepo
            case .tag(let tag):
                tag.repository.nameOfRepo
            case .detachedTag(let tag):
                tag.repository.nameOfRepo
            case .status(let status):
                status.repository.nameOfRepo
            case .stash(let stash):
                stash.repository.nameOfRepo
            }
        }
    }

    let type: DetailType
}
