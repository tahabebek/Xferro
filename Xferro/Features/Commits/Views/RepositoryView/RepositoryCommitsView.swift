//
//  RepositoryCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryCommitsView: View {
    let detachedTag: RepositoryViewModel.TagInfo?
    let detachedCommit: RepositoryViewModel.DetachedCommitInfo?
    let localBranches: [RepositoryViewModel.BranchInfo]
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
            if let detachedTag {
                BranchView(
                    viewModel: BranchViewModel(
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected,
                        onDeleteBranchTapped: onDeleteBranchTapped,
                        onIsCurrentBranch: onIsCurrentBranch
                    ),
                    name: "Detached tag \(detachedTag.tag.tag.name)",
                    selectableCommits: detachedTag.commits,
                    selectableStatus: selectableStatus,
                    isCurrent: true,
                    isDetached: true,
                    branchCount: localBranches.count
                )
                .animation(.default, value: detachedTag)
            } else if let detachedCommit {
                BranchView(
                    viewModel: BranchViewModel(
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected,
                        onDeleteBranchTapped: onDeleteBranchTapped,
                        onIsCurrentBranch: onIsCurrentBranch
                    ),
                    name: "Detached Commit",
                    selectableCommits: detachedCommit.commits,
                    selectableStatus: selectableStatus,
                    isCurrent: true,
                    isDetached: true,
                    branchCount: localBranches.count
                )
                .animation(.default, value: detachedCommit)
            }
            ForEach(localBranches) { branchInfo in
                BranchView(
                    viewModel: BranchViewModel(
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected,
                        onDeleteBranchTapped: onDeleteBranchTapped,
                        onIsCurrentBranch: onIsCurrentBranch
                    ),
                    name: branchInfo.branch.name,
                    selectableCommits: branchInfo.commits,
                    selectableStatus: selectableStatus,
                    isCurrent: (detachedTag != nil || detachedCommit != nil) ? false :
                        onIsCurrentBranch?(branchInfo.branch, head) ?? false,
                    isDetached: false,
                    branchCount: localBranches.count
                )
                .animation(.default, value: localBranches)
            }
        }
    }
}
