//
//  SelectableItemDetailView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct SelectableItemDetailView: View {
    let selectedItem: SelectedItem?
    let repository: Repository?
    let head: Head?

    var body: some View {
        VStack(spacing: 0) {
            if let selectedItem, let repository, let head {
                switch selectedItem.type {
                case .regular(let regularSelectedItem):
                    switch regularSelectedItem {
                    case .status(let selectableStatus):
                        StatusView(viewModel: StatusViewModel(
                            selectableStatus: selectableStatus,
                            repository: repository,
                            head: head
                        ))
                    case .commit(let selectableCommit):
                        CommitView()
                    case .historyCommit(let selectableHistoryCommit):
                        HistoryCommitView()
                    case .detachedCommit(let selectableDetachedCommit):
                        DetachedCommitView()
                    case .detachedTag(let selectableDetachedTag):
                        DetachedTagView()
                    case .tag(let selectableTag):
                        TagView()
                    case .stash(let selectableStash):
                        StashView()
                    }
                case .wip(let wipSelectedItem):
                    WipCommitView()
                }
            } else {
                VStack {
                    Spacer()
                    Text("Nothing is selected.")
                        .font(.body)
                    Spacer()
                }
            }
            Spacer(minLength: 0)
        }
    }
}
