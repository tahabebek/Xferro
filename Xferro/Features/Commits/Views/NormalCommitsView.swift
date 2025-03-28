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
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            VerticalHeader(title: "Repositories") {
                AddRepositoryButton(
                    onTapNewRepository: {
                        dismiss()
                        AppDelegate.newRepository()
                    },
                    onTapAddLocalRepository: {
                        dismiss()
                        AppDelegate.addLocalRepository()
                    },
                    onTapCloneRepository: {
                        dismiss()
                        AppDelegate.cloneRepository()
                    })
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
                        onTapPush: onTapPush,
                        onAddRemoteTapped: onAddRemoteTapped,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                        isSelected: viewModel.currentRepositoryInfo == repositoryInfo
                    )
                }
                if viewModel.currentRepositoryInfos.count == 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            AddRepositoryButton(
                                onTapNewRepository: {
                                    dismiss()
                                    AppDelegate.newRepository()
                                },
                                onTapAddLocalRepository: {
                                    dismiss()
                                    AppDelegate.addLocalRepository()
                                },
                                onTapCloneRepository: {
                                    dismiss()
                                    AppDelegate.cloneRepository()
                                })
                                .padding()
                            Spacer()
                        }
                        Spacer()
                    }
                    .border(.blue)
                }
                Spacer()
            }
        }
        .animation(.default, value: viewModel.currentRepositoryInfos.count)
    }
}
