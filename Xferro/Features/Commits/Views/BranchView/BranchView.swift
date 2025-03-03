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
    let name: String
    let selectableCommits: [any BranchItem]
    let selectableStatus: SelectableStatus
    let isCurrent: Bool
    let isDetached: Bool
    let branchCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                BranchMenuView(
                    showingBranchOptions: $showingBranchOptions,
                    isCurrent: isCurrent,
                    name: name,
                    isDetached: isDetached,
                    onDeleteBranchTapped: viewModel.onDeleteBranchTapped,
                    branchCount: branchCount
                )
                    .frame(maxWidth: 120)
                    .padding(.trailing, 8)
                BranchGraphView(
                    isCurrent: isCurrent,
                    selectableCommits: selectableCommits,
                    selectableStatus: selectableStatus,
                    onUserTapped: viewModel.onUserTapped,
                    onIsSelected: viewModel.onIsSelected
                )
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
