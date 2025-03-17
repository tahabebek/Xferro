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
    @State private var showingBranchOptions = false
    let viewModel: BranchViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                BranchMenuView(
                    showingBranchOptions: $showingBranchOptions,
                    isCurrent: viewModel.isCurrent,
                    name: viewModel.branchInfo.branch.name,
                    isDetached: false,
                    onDeleteBranchTapped: viewModel.onDeleteBranchTapped,
                    onPushBranchToRemoteTapped: viewModel.onPushBranchToRemoteTapped,
                    branchCount: viewModel.branchCount
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
