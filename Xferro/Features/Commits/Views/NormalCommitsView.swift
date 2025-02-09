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
                ForEach(viewModel.repositories) { repository in
                    RepositoryView(repository: repository)
                        .frame(width: width)
                }
                AddRepositoryButton()
                Spacer()
            }
            .frame(width: width)
            .fixedSize()
        }
        .id(viewModel.forceRefresh)
    }
}
