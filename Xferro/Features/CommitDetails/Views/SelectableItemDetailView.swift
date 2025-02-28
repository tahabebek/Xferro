//
//  SelectableItemDetailView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct SelectableItemDetailView: View {
    let commitsViewModel: CommitsViewModel
    let detailsViewModel: DetailsViewModel

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
                StatusView(commitsViewModel: commitsViewModel, statusViewModel: StatusViewModel(selectableStatus: selectableStatus))
            }
            Spacer(minLength: 0)
        }
    }
}
