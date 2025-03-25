//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct CommitsView: View {
    let commitsViewModel: CommitsViewModel

    let onPullTapped: (Repository.PullType) -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onPushTapped: (String, Remote?, Repository.PushType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void

    var body: some View {
        VSplitView {
            NormalCommitsView(
                viewModel: commitsViewModel,
                onPullTapped: onPullTapped,
                onFetchTapped: onFetchTapped,
                onTapPush: onPushTapped,
                onAddRemoteTapped: onAddRemoteTapped,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex
            )
                .padding(.trailing, 6)
            WipCommitsView(
                viewModel: commitsViewModel.currentWipCommits,
                currentSelectedItem: commitsViewModel.currentSelectedItem,
                onUserTapped: commitsViewModel.userTapped(item:repositoryInfo:),
                isSelectedItem: {
                    commitsViewModel.isSelected(item: $0)
                },
                onAddManualWipCommitTapped: {
                    commitsViewModel.addManualWipCommitTapped()
                }, onDeleteWipWorktreeTapped: {
                    commitsViewModel.deleteWipWorktreeTapped(for: $0)
                }, onAddRemoteTapped: onAddRemoteTapped,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onPushTapped: onPushTapped
            )
            .padding(.trailing, 6)
        }
    }
}

