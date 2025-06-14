//
//  RepositoryCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryCommitsView: View {
    let detachedTag: TagInfo?
    let detachedCommit: DetachedCommitInfo?
    let localBranches: [BranchInfo]
    let remoteBranches: [BranchInfo]
    let selectableStatus: SelectableStatus
    let head: Head
    let remotes: [Remote]
    let currentBranch: String

    let onUserTapped: ((any SelectableItem)) -> Void
    let onIsSelected: ((any SelectableItem)) -> Bool
    let onDeleteBranchTapped: (String) -> Void
    let onIsCurrentBranch: (Branch, Head) -> Bool
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onPullTapped: (Repository.PullType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void
    let onMergeOrRebase: (String, String, BranchOperationView.OperationType) -> Void

    var body: some View {
        guard detachedTag == nil || detachedCommit == nil else {
            fatalError(.impossible)
        }
        return VStack(spacing: 16) {
            if let detachedTag {
                DetachedTagBranchView(
                    viewModel: DetachedTagBranchViewModel(
                        tagInfo: detachedTag,
                        branchCount: localBranches.count,
                        selectableStatus: selectableStatus,
                        localBranches: localBranches.map(\.branch.name),
                        remoteBranches: remoteBranches.map(\.branch.name),
                        currentBranch: currentBranch,
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected,
                        onDeleteBranchTapped: onDeleteBranchTapped,
                        onIsCurrentBranch: onIsCurrentBranch,
                        onTapPush: onTapPush,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                        onAddRemoteTapped: onAddRemoteTapped,
                        onCreateBranchTapped: onCreateBranchTapped,
                        onCheckoutOrDelete: onCheckoutOrDelete,
                        onMergeOrRebase: onMergeOrRebase
                    ),
                    remotes: remotes
                )
                .animation(.default, value: detachedTag.id)
            } else if let detachedCommit {
                DetachedCommitBranchView(
                    viewModel: DetachedCommitBranchViewModel(
                        detachedCommitInfo: detachedCommit,
                        selectableStatus: selectableStatus,
                        branchCount: localBranches.count,
                        localBranches: localBranches.map(\.branch.name),
                        remoteBranches: remoteBranches.map(\.branch.name),
                        currentBranch: currentBranch,
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected,
                        onDeleteBranchTapped: onDeleteBranchTapped,
                        onIsCurrentBranch: onIsCurrentBranch,
                        onTapPush: onTapPush,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                        onAddRemoteTapped: onAddRemoteTapped,
                        onCreateBranchTapped: onCreateBranchTapped,
                        onCheckoutOrDelete: onCheckoutOrDelete,
                        onMergeOrRebase: onMergeOrRebase
                    ),
                    remotes: remotes
                )
                .animation(.default, value: detachedCommit.detachedCommit.id)
            }
            ForEach(localBranches) { branchInfo in
                BranchView(
                    viewModel: BranchViewModel(
                        branchInfo: branchInfo,
                        selectableStatus: selectableStatus,
                        isCurrent: (detachedTag != nil || detachedCommit != nil) ? false :
                            onIsCurrentBranch(branchInfo.branch, head),
                        branchCount: localBranches.count,
                        localBranches: localBranches.map(\.branch.name),
                        remoteBranches: remoteBranches.map(\.branch.name),
                        currentBranch: currentBranch,
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected,
                        onDeleteBranchTapped: onDeleteBranchTapped,
                        onIsCurrentBranch: onIsCurrentBranch,
                        onTapPush: onTapPush,
                        onPullTapped: onPullTapped,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                        onAddRemoteTapped: onAddRemoteTapped,
                        onCreateBranchTapped: onCreateBranchTapped,
                        onCheckoutOrDelete: onCheckoutOrDelete,
                        onMergeOrRebase: onMergeOrRebase
                    ),
                    remotes: remotes
                )
                .animation(
                    .default,
                    value: localBranches.count
                )
            }
        }
    }
}
