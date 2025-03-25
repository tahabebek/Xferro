//
//  NormalCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct NormalCommitsView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: CommitsViewModel

    let onPullTapped: (Repository.PullType) -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            VerticalHeader(title: "Repositories") {
                VStack(alignment: .leading, spacing: 8) {
                    AddRepositoryButton(viewModel: viewModel)
                    XFButton<Void>(
                        title: "Add Local Repository",
                        onTap: {
                            dismiss()
                            fatalError(.unimplemented)
                        }
                    )
                    XFButton<Void>(
                        title: "Clone Repository",
                        onTap: {
                            dismiss()
                            fatalError(.unimplemented)
                        }
                    )
                }
                .padding()
            }
            .frame(height: Dimensions.verticalHeaderHeight)
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.currentRepositoryInfos.values.elements) { repositoryInfo in
                    RepositoryView(
                        repositoryInfo: repositoryInfo,
                        onPullTapped: onPullTapped,
                        onFetchTapped: onFetchTapped,
                        onAddRemoteTapped: onAddRemoteTapped,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemote: onSetLastSelectedRemote,
                        isSelected: viewModel.currentRepositoryInfo == repositoryInfo
                    )
                }
                if viewModel.currentRepositoryInfos.count == 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack {
                                Text("No repositories found.")
                                AddRepositoryButton(viewModel: viewModel)
                                XFButton<Void>(
                                    title: "Add Local Repository",
                                    onTap: {
                                        fatalError(.unimplemented)
                                    }
                                )
                                XFButton<Void>(
                                    title: "Clone Repository",
                                    onTap: {
                                        fatalError(.unimplemented)
                                    }
                                )
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .animation(.default, value: viewModel.currentRepositoryInfos.count)
    }
}
