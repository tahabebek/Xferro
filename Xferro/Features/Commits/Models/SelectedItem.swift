//
//  SelectedItem.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

struct SelectedItem: Equatable {
    let type: SelectedItemType
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
