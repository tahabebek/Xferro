//
//  BranchGraphContentView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchGraphContentView: View {
    let index: Int
    let isCurrent: Bool
    let selectableStatus: SelectableStatus
    let selectableCommits: [any BranchItem]
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?

    var body: some View {
        ZStack {
            if isCurrent && index == 0 {
                BranchStatusCircleView(
                    selectableStatus: selectableStatus,
                    onIsSelected: onIsSelected,
                    onUserTapped: onUserTapped
                )
            } else {
                BranchCommitCircleView(
                    onUserTapped: onUserTapped,
                    onIsSelected: onIsSelected,
                    selectableCommits: selectableCommits,
                    isCurrent: isCurrent,
                    index: index
                )
            }
        }
    }
}
