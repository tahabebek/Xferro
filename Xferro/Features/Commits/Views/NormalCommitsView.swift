//
//  NormalCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct NormalCommitsView: View {
    let viewModel: CommitsViewModel
    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            VerticalHeader(title: "Repositories") {
                AddRepositoryButton(viewModel: viewModel)
                Image(systemName: "document.on.document")
                    .contentShape(Rectangle())
                    .hoverableButton("Clone a repostory") {
                        fatalError()
                    }
            }
            .frame(height: 36)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.currentRepositoryInfos.values.elements) { repositoryInfo in
                    RepositoryView(viewModel: viewModel, repositoryInfo: repositoryInfo)
                }
                if viewModel.currentRepositoryInfos.count == 0 {
                    HStack {
                        Spacer()
                        VStack {
                            Text("No repositories found.")
                            AddRepositoryButton(viewModel: viewModel)
                        }
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .animation(.default, value: viewModel.currentRepositoryInfos)
    }
}
