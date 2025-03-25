//
//  WipCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WipCommitsView: View {
    let viewModel: WipCommitsViewModel?
    let currentSelectedItem: SelectedItem?
    let onUserTapped: (any SelectableItem, RepositoryInfo) -> Void
    let isSelectedItem: (any SelectableItem) -> Bool
    let onAddManualWipCommitTapped: () -> Void
    let onDeleteWipWorktreeTapped: (Repository) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void
    let onPushTapped: (String, Remote?, Repository.PushType) async throws -> Void

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            if let viewModel {
                WipHeaderView(
                    viewModel: viewModel,
                    onAddManualWipCommitTapped: onAddManualWipCommitTapped,
                    onDeleteWipWorktreeTapped: {
                        viewModel.commits = []
                        onDeleteWipWorktreeTapped(viewModel.repositoryInfo.repository)
                    },
                    onAddRemoteTapped: onAddRemoteTapped,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemote: onSetLastSelectedRemote,
                    onPushTapped: onPushTapped
                )
                .padding(.top, 8)
            }
        } content: {
            if let viewModel {
                WipCommitsContentView(
                    wipDescription: "Wip branch of \(viewModel.item.selectableItem.wipDescription)",
                    commits: viewModel.commits,
                    onUserTapped: {
                        onUserTapped($0, viewModel.repositoryInfo)
                    },
                    onIsSelected: isSelectedItem
                )
            }
        }
    }
}
