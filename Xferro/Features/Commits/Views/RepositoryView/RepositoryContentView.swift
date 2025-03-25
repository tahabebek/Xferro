//
//  RepositoryContentView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryContentView: View {
    let selection: RepositoryView.Section
    @Namespace private var animation

    let tags: [TagInfo]
    let stashes: [SelectableStash]
    let historyCommits: [SelectableHistoryCommit]
    let detachedTag: TagInfo?
    let detachedCommit: DetachedCommitInfo?
    let localBranches: [BranchInfo]
    let remoteBranches: [BranchInfo]
    let currentBranch: String
    let selectableStatus: SelectableStatus
    let head: Head
    let remotes: [Remote]

    let onUserTapped: ((any SelectableItem)) -> Void
    let onIsSelected: ((any SelectableItem)) -> Bool
    let onDeleteBranchTapped: (String) -> Void
    let onIsCurrentBranch: (Branch, Head) -> Bool
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void
    let onMergeOrRebase: (String, String, BranchOperationView.OperationType) -> Void

    var body: some View {
        Group {
            switch selection {
            case .commits:
                RepositoryCommitsView(
                    detachedTag: detachedTag,
                    detachedCommit: detachedCommit,
                    localBranches: localBranches,
                    remoteBranches: remoteBranches,
                    selectableStatus: selectableStatus,
                    head: head,
                    remotes: remotes,
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
                )
                    .matchedGeometryEffect(id: "contentView", in: animation)
            case .tags:
                RepositoryTagsView(
                    tags: tags,
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected
                )
                    .matchedGeometryEffect(id: "contentView", in: animation)
            case .stashes:
                RepositoryStashesView(
                    stashes: stashes,
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected
                )
                    .matchedGeometryEffect(id: "contentView", in: animation)
            case .history:
                RepositoryHistoryView(historyCommits: historyCommits)
                    .matchedGeometryEffect(id: "contentView", in: animation)
            }
        }
        .animation(.default, value: selection)
    }
}
