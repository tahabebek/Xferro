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
                    onDeleteBranchTapped: viewModel.onDeleteBranchTapped,
                    onTapPush: viewModel.onTapPush,
                    onGetLastSelectedRemoteIndex: viewModel.onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: viewModel.onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: viewModel.onAddRemoteTapped,
                    onCreateBranchTapped: viewModel.onCreateBranchTapped,
                    onCheckoutOrDelete: viewModel.onCheckoutOrDelete,
                    onMergeOrRebase: viewModel.onMergeOrRebase
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
