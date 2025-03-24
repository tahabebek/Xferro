//
//  RepositoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import Observation
import SwiftUI

struct RepositoryView: View {
    enum Section: Int {
        case commits = 0
        case tags = 1
        case stashes = 2
        case history = 3
    }

    @Bindable var repositoryInfo: RepositoryInfo
    @State private var isCollapsed = false
    @State private var selection: Section = .commits

    let onPullTapped: (StatusViewModel.PullType) -> Void
    let onFetchTapped: (StatusViewModel.FetchType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void
    let isSelected: Bool

    var body: some View {
        Group {
            VStack(spacing: 0) {
                RepositoryMenuView(
                    isCollapsed: $isCollapsed,
                    errorString: $repositoryInfo.errorString,
                    showError: $repositoryInfo.showError,
                    onDeleteRepositoryTapped: repositoryInfo.deleteRepositoryTapped,
                    onPullTapped: onPullTapped,
                    onFetchTapped: onFetchTapped,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemote: onSetLastSelectedRemote,
                    onCreateBranchTapped: repositoryInfo.createBranchTapped,
                    onBranchOperationTapped: {
                        switch $2 {
                        case .checkout:
                            repositoryInfo.checkoutBranchTapped(branchName: $0, isRemote: $1)
                        case .delete:
                            repositoryInfo.deleteBranchTapped(branchName: $0, isRemote: $1)
                        case .merge, .rebase:
                            fatalError(.unimplemented)
                        }
                    },
                    onCreateTagTapped: repositoryInfo.createTagTapped,
                    gitDir: repositoryInfo.repository.gitDir,
                    head: repositoryInfo.head,
                    remotes: repositoryInfo.remotes,
                    localBranches: repositoryInfo.localBranchInfos,
                    remoteBranches: repositoryInfo.remoteBranchInfos,
                    isSelected: isSelected
                )
                .frame(height: 36)
                if !isCollapsed {
                    VStack(spacing: 16) {
                        RepositoryPickerView(selection: $selection)
                            .frame(height: 24)
                        RepositoryContentView(
                            selection: selection,
                            tags: repositoryInfo.tags,
                            stashes: repositoryInfo.stashes,
                            historyCommits: repositoryInfo.historyCommits,
                            detachedTag: repositoryInfo.detachedTag,
                            detachedCommit: repositoryInfo.detachedCommit,
                            localBranches: repositoryInfo.localBranchInfos,
                            onUserTapped: repositoryInfo.onUserTapped,
                            onIsSelected: repositoryInfo.onIsSelected,
                            onDeleteBranchTapped: repositoryInfo.onDeleteBranchTapped,
                            onIsCurrentBranch: repositoryInfo.onIsCurrentBranch,
                            onPushBranchToRemoteTapped: repositoryInfo.onPushBranchToRemoteTapped,
                            selectableStatus: SelectableStatus(repositoryInfo: repositoryInfo),
                            head: repositoryInfo.head
                        )
                        .padding(.bottom, 8)
                }
                    .frame(maxHeight: !isCollapsed ? .infinity : 0)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, !isCollapsed ? 8 : 0)
        }
        .animation(.default, value: repositoryInfo.head)
        .animation(.default, value: isCollapsed)
        .background(
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
        )
    }
}
