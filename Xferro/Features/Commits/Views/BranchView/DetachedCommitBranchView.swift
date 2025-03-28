//
//  DetachedCommitBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import SwiftUI

struct DetachedCommitBranchView: View {
    let viewModel: DetachedCommitBranchViewModel
    let remotes: [Remote]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                BranchMenuView(
                    remotes: remotes,
                    isCurrent: true,
                    name: "Detached Commit",
                    isDetached: true,
                    branchCount: viewModel.branchCount,
                    localBranches: viewModel.localBranches,
                    remoteBranches: viewModel.remoteBranches,
                    currentBranch: viewModel.currentBranch,
                    onDeleteBranchTapped: { _ in },
                    onTapPush: { _, _, _ in },
                    onPullTapped: { _ in },
                    onGetLastSelectedRemoteIndex: { _ in 0 },
                    onSetLastSelectedRemoteIndex: { _, _ in },
                    onAddRemoteTapped: { },
                    onCreateBranchTapped: viewModel.onCreateBranchTapped,
                    onCheckoutOrDelete: { _, _, _ in },
                    onMergeOrRebase: { _, _, _ in }
                )
                .frame(maxWidth: 120)
                .padding(.trailing, 8)
                DetachedCommitBranchGraphView(
                    detachedCommitInfo: viewModel.detachedCommitInfo,
                    selectableStatus: viewModel.selectableStatus,
                    onUserTapped: viewModel.onUserTapped,
                    onIsSelected: viewModel.onIsSelected
                )
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
