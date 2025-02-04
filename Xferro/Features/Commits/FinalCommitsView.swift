//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct FinalCommitsView: View {
    @State var viewModel: CommitsViewModel
    let width: CGFloat

    var body: some View {
        PinnedScrollableView(title: "Final Commits") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.repositories) { repository in
                    RepositoryView(viewModel: viewModel, repository: repository)
                        .frame(width: width)
                }
                AddRepositoryButton(viewModel: viewModel)
                Spacer()
            }
            .fixedSize()
            .frame(width: width)
        }
    }
}
