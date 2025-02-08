//
//  CommitsViewModel+SelectedItem.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

extension CommitsViewModel {
    struct SelectedItem: Equatable {
        let selectedItemType: SelectedItemType

        var repository: Repository {
            switch selectedItemType {
            case .regular(let regularSelectedItem):
                regularSelectedItem.repository
            case .wip(let wipSelectedItem):
                wipSelectedItem.repository
            }
        }

        var selectableItem: any SelectableItem {
            switch selectedItemType {
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

            var repository: Repository {
                switch self {
                case .wipCommit(let selectableWipCommit):
                    selectableWipCommit.repository
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

            var repository: Repository {
                switch self {
                case .status(let selectableStatus):
                    selectableStatus.repository
                case .commit(let selectableCommit):
                    selectableCommit.repository
                case .historyCommit(let selectableHistoryCommit):
                    selectableHistoryCommit.repository
                case .detachedCommit(let selectableDetachedCommit):
                    selectableDetachedCommit.repository
                case .detachedTag(let selectableDetachedTag):
                    selectableDetachedTag.repository
                case .tag(let selectableTag):
                    selectableTag.repository
                case .stash(let selectableStash):
                    selectableStash.repository
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
}
