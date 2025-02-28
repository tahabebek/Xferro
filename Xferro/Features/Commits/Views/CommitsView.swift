//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct CommitsView: View {
    let commitsViewModel: CommitsViewModel
    var body: some View {
        VSplitView {
            NormalCommitsView(viewModel: commitsViewModel)
                .padding(.trailing, 6)
            WipCommitsView(
                wipCommits: commitsViewModel.currentWipCommits,
                currentSelectedItem: commitsViewModel.currentSelectedItem
            ) {
                commitsViewModel.userTapped(item: $0)
            } isSelectedItem: {
                commitsViewModel.isSelected(item: $0)
            } onAddManualWipCommitTapped: {
                commitsViewModel.addManualWipCommitTapped(for: $0)
            } onDeleteWipWorktreeTapped: {
                commitsViewModel.deleteRepositoryButtonTapped($0)
            } onDeleteAllWipCommitsTapped: {
                commitsViewModel.deleteAllWipCommitsTapped(for: $0)
            }
            .padding(.trailing, 6)
        }
    }
}

