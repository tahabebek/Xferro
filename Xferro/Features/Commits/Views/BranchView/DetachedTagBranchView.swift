//
//  DetachedTagBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import SwiftUI

struct DetachedTagBranchView: View {
    let viewModel: DetachedTagBranchViewModel
    let remotes: [Remote]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                BranchMenuView(
                    remotes: remotes,
                    isCurrent: true,
                    name: "Detached tag \(viewModel.tagInfo.tag.tag.name)",
                    isDetached: true,
                    branchCount: viewModel.branchCount,
                    localBranches: viewModel.localBranches,
                    remoteBranches: viewModel.remoteBranches,
                    currentBranch: viewModel.currentBranch,
                    onDeleteBranchTapped: viewModel.onDeleteBranchTapped,
                    onTapPush: viewModel.onTapPush,
                    onPullTapped: { _ in },
                    onGetLastSelectedRemoteIndex: viewModel.onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: viewModel.onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: viewModel.onAddRemoteTapped,
                    onCreateBranchTapped: viewModel.onCreateBranchTapped,
                    onCheckoutOrDelete: viewModel.onCheckoutOrDelete,
                    onMergeOrRebase: viewModel.onMergeOrRebase
                )
                .frame(maxWidth: 120)
                .padding(.trailing, 8)
                DetachedTagBranchGraphView(
                    detachedTagInfo: viewModel.tagInfo,
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
