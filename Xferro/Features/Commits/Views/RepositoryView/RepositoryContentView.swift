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
    let onUserTapped: (((any SelectableItem)) -> Void)?
    let onIsSelected: (((any SelectableItem)) -> Bool)?
    let onDeleteBranchTapped: ((String) -> Void)?
    let onIsCurrentBranch: ((Branch, Head) -> Bool)?
    let onPushBranchToRemoteTapped: ((String) -> Void)?
    let selectableStatus: SelectableStatus
    let head: Head

    var body: some View {
        Group {
            switch selection {
            case .commits:
                RepositoryCommitsView(
                    detachedTag: detachedTag,
                    detachedCommit: detachedCommit,
                    localBranches: localBranches,
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected,
                    onDeleteBranchTapped: onDeleteBranchTapped,
                    onIsCurrentBranch: onIsCurrentBranch,
                    onPushBranchToRemoteTapped: onPushBranchToRemoteTapped,
                    selectableStatus: selectableStatus,
                    head: head
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
