//
//  BranchGraphView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchGraphView: View {
    let isCurrent: Bool
    let selectableCommits: [any BranchItem]
    let selectableStatus: SelectableStatus
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?

    var body: some View {
        CirclesWithArrows(
            numberOfCircles: isCurrent ? selectableCommits.count + 1 : selectableCommits.count,
            circleSize: BranchView.commitNodeSize,
            spacing: 12
        ) { index in
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
}
