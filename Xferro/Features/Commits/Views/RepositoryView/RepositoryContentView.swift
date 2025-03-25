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

    var body: some View {
        Group {
            switch selection {
            case .commits:
                RepositoryCommitsView(
                    detachedTag: detachedTag,
                    detachedCommit: detachedCommit,
                    localBranches: localBranches,
                    selectableStatus: selectableStatus,
                    head: head,
                    remotes: remotes,
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected,
                    onDeleteBranchTapped: onDeleteBranchTapped,
                    onIsCurrentBranch: onIsCurrentBranch,
                    onTapPush: onTapPush,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onCreateBranchTapped: onCreateBranchTapped
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
