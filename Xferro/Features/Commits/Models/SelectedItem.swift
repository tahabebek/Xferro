//
//  SelectedItem.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

struct SelectedItem: Equatable {
    let type: SelectedItemType

    var repositoryInfo: RepositoryInfo {
        switch type {
        case .regular(let regularSelectedItem):
            regularSelectedItem.repositoryInfo
        case .wip(let wipSelectedItem):
            wipSelectedItem.repositoryInfo
        }
    }

    var repository: Repository {
        repositoryInfo.repository
    }

    var wipWorktree: WipWorktree {
        switch type {
        case .regular(let regularSelectedItem):
            regularSelectedItem.repositoryInfo.wipWorktree
        case .wip(let wipSelectedItem):
            wipSelectedItem.repositoryInfo.wipWorktree
        }
    }

    var oid: OID {
        switch type {
        case .regular(let regularSelectedItem):
            regularSelectedItem.selectableItem.oid
        case .wip(let wipSelectedItem):
            switch wipSelectedItem {
            case .wipCommit(let selectableWipCommit):
                selectableWipCommit.oid
            }
        }
    }

    var selectableItem: any SelectableItem {
        switch type {
        case .regular(let regularSelectedItem):
            regularSelectedItem.selectableItem
        case .wip(let wipSelectedItem):
            wipSelectedItem.selectableItem
        }
    }

    enum SelectedItemType: Equatable {
        case regular(RegularSelectedItem)
        case wip(WipSelectedItem)
    }

    enum WipSelectedItem: Equatable {
        case wipCommit(SelectableWipCommit)

        var repositoryInfo: RepositoryInfo {
            switch self {
            case .wipCommit(let selectableWipCommit):
                selectableWipCommit.repositoryInfo
            }
        }
        
        var repository: Repository {
            repositoryInfo.repository
        }

        var wipWorktree: WipWorktree {
            switch self {
            case .wipCommit(let selectableWipCommit):
                selectableWipCommit.repositoryInfo.wipWorktree
            }
        }
        var selectableItem: any SelectableItem {
            switch self {
            case .wipCommit(let selectableWipCommit):
                selectableWipCommit
            }
        }
    }
    enum RegularSelectedItem: Equatable {
        case status(SelectableStatus)
        case commit(SelectableCommit)
        case historyCommit(SelectableHistoryCommit)
        case detachedCommit(SelectableDetachedCommit)
        case detachedTag(SelectableDetachedTag)
        case tag(SelectableTag)
        case stash(SelectableStash)

        var repositoryInfo: RepositoryInfo {
            switch self {
            case .status(let selectableStatus):
                selectableStatus.repositoryInfo
            case .commit(let selectableCommit):
                selectableCommit.repositoryInfo
            case .historyCommit(let selectableHistoryCommit):
                selectableHistoryCommit.repositoryInfo
            case .detachedCommit(let selectableDetachedCommit):
                selectableDetachedCommit.repositoryInfo
            case .detachedTag(let selectableDetachedTag):
                selectableDetachedTag.repositoryInfo
            case .tag(let selectableTag):
                selectableTag.repositoryInfo
            case .stash(let selectableStash):
                selectableStash.repositoryInfo
            }
        }

        var repository: Repository {
            repositoryInfo.repository
        }

        var wipWorktree: WipWorktree {
            switch self {
            case .status(let selectableStatus):
                selectableStatus.repositoryInfo.wipWorktree
            case .commit(let selectableCommit):
                selectableCommit.repositoryInfo.wipWorktree
            case .historyCommit(let selectableHistoryCommit):
                selectableHistoryCommit.repositoryInfo.wipWorktree
            case .detachedCommit(let selectableDetachedCommit):
                selectableDetachedCommit.repositoryInfo.wipWorktree
            case .detachedTag(let selectableDetachedTag):
                selectableDetachedTag.repositoryInfo.wipWorktree
            case .tag(let selectableTag):
                selectableTag.repositoryInfo.wipWorktree
            case .stash(let selectableStash):
                selectableStash.repositoryInfo.wipWorktree
            }
        }

        var selectableItem: any SelectableItem {
            switch self {
            case .status(let selectableStatus):
                selectableStatus
            case .commit(let selectableCommit):
                selectableCommit
            case .historyCommit(let selectableHistoryCommit):
                selectableHistoryCommit
            case .detachedCommit(let selectableDetachedCommit):
                selectableDetachedCommit
            case .detachedTag(let selectableDetachedTag):
                selectableDetachedTag
            case .tag(let selectableTag):
                selectableTag
            case .stash(let selectableStash):
                selectableStash
            }
        }
    }
}
