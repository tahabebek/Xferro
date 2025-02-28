//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct CommitsView: View {
    @Environment(CommitsViewModel.self) var commitsViewModel
    var body: some View {
        VSplitView {
            NormalCommitsView()
                .padding(.trailing, 6)
            WipCommitsView(
                wipCommits: commitsViewModel.currentWipCommits,
                onUserTapped: { item in
                    commitsViewModel.userTapped(item: item)
                },
                isSelectedItem: { item in
                    commitsViewModel.isSelected(item: item)
                }
            )
                .padding(.trailing, 6)
        }
    }
}

