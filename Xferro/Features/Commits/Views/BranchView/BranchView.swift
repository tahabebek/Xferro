//
//  BranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

protocol BranchItem: SelectableItem {
    var commit: Commit { get }
}

struct BranchView: View {
    static let commitNodeSize: CGFloat = 54
    let viewModel: BranchViewModel
    let remotes: [Remote]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                BranchMenuView(
                    remotes: remotes,
                    isCurrent: viewModel.isCurrent,
                    name: viewModel.branchInfo.branch.name,
                    isDetached: false,
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
                BranchGraphView(
                    isCurrent: viewModel.isCurrent,
                    branchInfo: viewModel.branchInfo,
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
