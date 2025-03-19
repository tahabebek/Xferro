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

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            if let viewModel {
                WipHeaderView(
                    autoCommitEnabled: Binding<Bool>(
                        get: { viewModel.autoCommitEnabled },
                        set: { viewModel.autoCommitEnabled = $0 }
                    ),
                    onAddManualWipCommitTapped: onAddManualWipCommitTapped,
                    onDeleteWipWorktreeTapped: {
                        viewModel.commits = []
                        onDeleteWipWorktreeTapped(viewModel.repositoryInfo.repository)
                    },
                    tooltipForDeleteRepo: "Delete all wip commits of \(viewModel.repositoryInfo.repository.nameOfRepo)",
                    tooltipForDeleteBranch: currentSelectedItem != nil ?
                    "Delete wip commits of \(currentSelectedItem!.selectableItem.wipDescription.uncapitalizingFirstLetter())" : nil,
                    isNotEmpty: viewModel.isNotEmpty)
                .frame(height: 36)
                .padding(.top, 8)
            }
        } content: {
            if let currentSelectedItem, let viewModel {
                WipCommitsContentView(
                    wipDescription: currentSelectedItem.selectableItem.wipDescription,
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
