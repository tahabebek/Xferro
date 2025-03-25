//
//  DetachedTagBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import SwiftUI

struct DetachedTagBranchView: View {
    @State private var showingBranchOptions = false
    let viewModel: DetachedTagBranchViewModel
    let remotes: [Remote]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                BranchMenuView(
                    showingBranchOptions: $showingBranchOptions,
                    remotes: remotes,
                    isCurrent: true,
                    name: "Detached tag \(viewModel.tagInfo.tag.tag.name)",
                    isDetached: true,
                    branchCount: viewModel.branchCount,
                    onDeleteBranchTapped: viewModel.onDeleteBranchTapped,
                    onTapPush: viewModel.onTapPush,
                    onGetLastSelectedRemoteIndex: viewModel.onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: viewModel.onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: viewModel.onAddRemoteTapped
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
