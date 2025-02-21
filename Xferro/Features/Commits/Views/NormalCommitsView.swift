//
//  NormalCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct NormalCommitsView: View {
    @Environment(CommitsViewModel.self) var viewModel

    var body: some View {
        let _ = Self._printChanges()
        PinnedScrollableView(showsIndicators: false) {
            VerticalHeader(title: "Repositories") {
                AddRepositoryButton()
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
                    RepositoryView()
                        .environment(viewModel.repositoryViewModel(for: repositoryInfo.repository))
                }
                if viewModel.currentRepositoryInfos.count == 0 {
                    HStack {
                        Spacer()
                        VStack {
                            Text("No repositories found.")
                            AddRepositoryButton()
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
