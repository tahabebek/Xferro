//
//  SelectableItemDetailView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct SelectableItemDetailView: View {
    let selectedItem: SelectedItem?
    let discardTapped: (Repository, [URL]) -> Void
    let commitTapped: (Repository, String) -> Void
    let amendTapped: (Repository, String?) -> Void
    let stageAllTapped: (Repository) -> Void
    let stageOrUnstageTapped: (Bool, Repository, [DeltaInfo]) -> Void
    let ignoreTapped: (Repository, DeltaInfo) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let selectedItem {
                switch selectedItem.type {
                case .regular(let regularSelectedItem):
                    switch regularSelectedItem {
                    case .status(let selectableStatus):
                        StatusView(
                            statusViewModel: StatusViewModel(selectableStatus: selectableStatus),
                            discardTapped: discardTapped,
                            commitTapped: commitTapped,
                            amendTapped: amendTapped,
                            stageAllTapped: stageAllTapped,
                            stageOrUnstageTapped: stageOrUnstageTapped,
                            ignoreTapped: ignoreTapped
                        )
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
