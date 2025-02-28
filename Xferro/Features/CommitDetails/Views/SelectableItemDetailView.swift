//
//  SelectableItemDetailView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct SelectableItemDetailView: View {
    let detailsViewModel: DetailsViewModel
    let getDeltaInfo: (OID) -> DeltaInfo?
    let setDeltaInfo: (OID, DeltaInfo) -> Void
    let discardTapped: (Repository, [URL]) -> Void
    let commitTapped: (Repository, String) -> Void
    let amendTapped: (Repository, String?) -> Void
    let stageAllTapped: (Repository) -> Void
    let stageOrUnstageTapped: (Bool, Repository, [DeltaInfo]) -> Void
    let ignoreTapped: (Repository, DeltaInfo) -> Void

    var body: some View {
        VStack(spacing: 0) {
            switch detailsViewModel.detailInfo.type {
            case .empty:
                VStack {
                    Spacer()
                    Text("Nothing is selected.")
                        .font(.body)
                    Spacer()
                }
            case .commit(let commit):
                CommitView()
            case .detachedCommit(let commit):
                DetachedCommitView()
            case .historyCommit(let commit):
                HistoryCommitView()
            case .wipCommit(let commit, let worktree):
                WipCommitView()
            case .tag(let tag):
                TagView()
            case .detachedTag(let tag):
                DetachedTagView()
            case .stash(let stash):
                StashView()
            case .status(let selectableStatus):
                StatusView(
                    statusViewModel: StatusViewModel(selectableStatus: selectableStatus),
                    getDeltaInfo: getDeltaInfo,
                    setDeltaInfo: setDeltaInfo,
                    discardTapped: discardTapped,
                    commitTapped: commitTapped,
                    amendTapped: amendTapped,
                    stageAllTapped: stageAllTapped,
                    stageOrUnstageTapped: stageOrUnstageTapped,
                    ignoreTapped: ignoreTapped
                )
            }
            Spacer(minLength: 0)
        }
    }
}
