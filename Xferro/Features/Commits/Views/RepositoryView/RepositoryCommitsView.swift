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
    let onUserTapped: (((any SelectableItem)) -> Void)?
    let onIsSelected: (((any SelectableItem)) -> Bool)?
    let onDeleteBranchTapped: ((String) -> Void)?
    let onIsCurrentBranch: ((Branch, Head) -> Bool)?
    let selectableStatus: SelectableStatus
    let head: Head

    var body: some View {
        guard detachedTag == nil || detachedCommit == nil else {
            fatalError(.impossible)
        }
        return VStack(spacing: 16) {
            if var detachedTag {
                DetachedTagBranchView(viewModel: DetachedTagBranchViewModel(
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected,
                    onDeleteBranchTapped: onDeleteBranchTapped,
                    onIsCurrentBranch: onIsCurrentBranch,
                    tagInfo: detachedTag,
                    branchCount: localBranches.count,
                    selectableStatus: selectableStatus
                ))
                .animation(.default, value: detachedTag.id)
            } else if var detachedCommit {
                DetachedCommitBranchView(viewModel: DetachedCommitBranchViewModel(
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected,
                    onDeleteBranchTapped: onDeleteBranchTapped,
                    onIsCurrentBranch: onIsCurrentBranch,
                    detachedCommitInfo: detachedCommit,
                    branchCount: localBranches.count,
                    selectableStatus: selectableStatus
                ))
                .animation(.default, value: detachedCommit.detachedCommit.id)
            }
            ForEach(localBranches) { branchInfo in
                BranchView(viewModel: BranchViewModel(
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected,
                    onDeleteBranchTapped: onDeleteBranchTapped,
                    onIsCurrentBranch: onIsCurrentBranch,
                    branchInfo: branchInfo,
                    isCurrent: (detachedTag != nil || detachedCommit != nil) ? false :
                        onIsCurrentBranch?(branchInfo.branch, head) ?? false,
                    branchCount: localBranches.count,
                    selectableStatus: selectableStatus
                ))
                .animation(.default, value: localBranches.count)
            }
        }
    }
}
