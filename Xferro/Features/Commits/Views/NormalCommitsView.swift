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
            HStack {
                VerticalHeader(title: "Repositories")
                Spacer()
                if viewModel.currentRepositoryInfos.count != 0 {
                    AddRepositoryButton()
                }
            }
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.currentRepositoryInfos.values.elements) { repositoryInfo in
                    RepositoryView()
                        .frame(width: width)
                        .environment(viewModel.repositoryViewModel(for: repositoryInfo.repository))
                }
                if viewModel.currentRepositoryInfos.count == 0 {
                    Text("No repositories found.")
                    AddRepositoryButton()
                }
                Spacer()
            }
            .frame(width: width)
            .fixedSize()
        }
    }
}
