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

    let onPullTapped: (Repository.PullType) -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let isSelected: Bool

    var body: some View {
        Group {
            VStack(spacing: 0) {
                menuView
                .frame(height: 36)
                if !isCollapsed {
                    VStack(spacing: 16) {
                        RepositoryPickerView(selection: $selection)
                            .frame(height: 24)
                        contentView
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

    var contentView: some View {
        RepositoryContentView(
            selection: selection,
            tags: repositoryInfo.tags,
            stashes: repositoryInfo.stashes,
            historyCommits: repositoryInfo.historyCommits,
            detachedTag: repositoryInfo.detachedTag,
            detachedCommit: repositoryInfo.detachedCommit,
            localBranches: repositoryInfo.localBranchInfos,
            remoteBranches: repositoryInfo.remoteBranchInfos,
            currentBranch: repositoryInfo.head.name,
            selectableStatus: SelectableStatus(repositoryInfo: repositoryInfo),
            head: repositoryInfo.head,
            remotes: repositoryInfo.remotes,
            onUserTapped: repositoryInfo.onUserTapped ?? { _ in },
            onIsSelected: repositoryInfo.onIsSelected ?? { _ in false },
            onDeleteBranchTapped: repositoryInfo.onDeleteBranchTapped ?? { _ in },
            onIsCurrentBranch: repositoryInfo.onIsCurrentBranch ?? { _, _ in false },
            onTapPush: onTapPush,
            onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
            onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
            onAddRemoteTapped: onAddRemoteTapped,
            onCreateBranchTapped: repositoryInfo.createBranchTapped,
            onCheckoutOrDelete: {
                switch $2 {
                case .checkout:
                    repositoryInfo.checkoutBranchTapped(branchName: $0, isRemote: $1)
                case .delete:
                    repositoryInfo.deleteBranchTapped(branchName: $0, isRemote: $1)
                default:
                    fatalError(.invalid)
                }
            },
            onMergeOrRebase: {
                switch $2 {
                case .merge:
                    repositoryInfo.rebaseBranchTapped(source: $0, target: $1)
                case .rebase:
                    repositoryInfo.rebaseBranchTapped(source: $0, target: $1)
                default:
                    fatalError(.invalid)
                }
            }
        )
    }

    var menuView: some View {
        RepositoryMenuView(
            isCollapsed: $isCollapsed,
            gitDir: repositoryInfo.repository.gitDir,
            head: repositoryInfo.head,
            remotes: repositoryInfo.remotes,
            isSelected: isSelected,
            localBranchNames: repositoryInfo.localBranchInfos.map(\.branch.name),
            remoteBranchNames: repositoryInfo.remoteBranchInfos.map(\.branch.name),
            onDeleteRepositoryTapped: repositoryInfo.deleteRepositoryTapped,
            onPullTapped: onPullTapped,
            onFetchTapped: onFetchTapped,
            onAddRemoteTapped: onAddRemoteTapped,
            onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
            onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
            onCreateTagTapped: repositoryInfo.createTagTapped,
            onCreateBranchTapped: repositoryInfo.createBranchTapped,
            onCheckoutOrDelete: {
                switch $2 {
                case .checkout:
                    repositoryInfo.checkoutBranchTapped(branchName: $0, isRemote: $1)
                case .delete:
                    repositoryInfo.deleteBranchTapped(branchName: $0, isRemote: $1)
                default:
                    fatalError(.unimplemented)
                }
            },
            onMergeOrRebase: {
                switch $2 {
                case .merge:
                    repositoryInfo.rebaseBranchTapped(source: $0, target: $1)
                case .rebase:
                    repositoryInfo.rebaseBranchTapped(source: $0, target: $1)
                default:
                    fatalError(.unimplemented)
                }
            }
        )
    }
}
