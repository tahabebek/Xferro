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
                viewModel: commitsViewModel.currentWipCommits,
                currentSelectedItem: commitsViewModel.currentSelectedItem
            ) {
                commitsViewModel.userTapped(item: $0, repositoryInfo: $1)
            } isSelectedItem: {
                commitsViewModel.isSelected(item: $0)
            } onAddManualWipCommitTapped: {
                commitsViewModel.addManualWipCommitTapped()
            } onDeleteWipWorktreeTapped: {
                commitsViewModel.deleteRepositoryTapped($0)
            }
            .padding(.trailing, 6)
        }
    }
}

