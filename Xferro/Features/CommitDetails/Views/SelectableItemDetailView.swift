//
//  SelectableItemDetailView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct SelectableItemDetailView: View {
    @Environment(DetailsViewModel.self) var viewModel
    var body: some View {
        VStack {
            switch viewModel.detailInfo.type {
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
            case .status(let selectableStatus, let statusEntries):
                StatusView()
                    .environment(StatusViewModel(selectableStatus: selectableStatus, statusEntries: statusEntries))
            }
            Spacer()
        }
        .frame(width: Dimensions.commitDetailsViewIdealWidth)
    }
}
