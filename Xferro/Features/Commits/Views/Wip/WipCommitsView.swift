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
    let onUserTapped: (any SelectableItem, RepositoryViewModel) -> Void
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
                        onDeleteWipWorktreeTapped(viewModel.repositoryInfo.repository)
                    },
                    tooltipForDeletion: "Delete all wip commits for \(viewModel.repositoryInfo.repository.nameOfRepo)",
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
                        onUserTapped(currentSelectedItem.selectableItem, viewModel.repositoryInfo)
                    },
                    onIsSelected: isSelectedItem
                )
            }
        }
    }

    func wipRectangle(item: SelectableWipCommit) -> some View {
        ZStack {
            Circle()
            .fill(Color.accentColor.opacity(0.7))
                .frame(width: 16, height: 16)
                .overlay(
                    Text("\(item.commit.oid.debugOID.prefix(2))")
                        .foregroundColor(.white)
                        .font(.system(size: 8))
                )
                .onTapGesture {
                    if let viewModel {
                        onUserTapped(item, viewModel.repositoryInfo)
                    }
                }
            if isSelectedItem(item) {
                SelectedItemOverlay(width: 16, height: 16, cornerRadius: 1)
            }
        }
    }
}
