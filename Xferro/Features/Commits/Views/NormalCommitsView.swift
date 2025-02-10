//
//  NormalCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct NormalCommitsView: View {
    @Environment(CommitsViewModel.self) var viewModel
    let width: CGFloat

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            VerticalHeader(title: "Repositories")
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.currentRepositoryInfos.values.elements) { repositoryInfo in
                    RepositoryView()
                        .frame(width: width)
                        .environment(viewModel.repositoryViewModel(for: repositoryInfo.repository))
                }
                AddRepositoryButton()
                Spacer()
            }
            .frame(width: width)
            .fixedSize()
        }
    }
}
