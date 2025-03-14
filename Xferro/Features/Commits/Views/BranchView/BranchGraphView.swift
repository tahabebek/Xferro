//
//  BranchGraphView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchGraphView: View {
    @State var selectableCommits: [SelectableCommit]?
    let isCurrent: Bool
    let branchInfo: BranchInfo
    let selectableStatus: SelectableStatus
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?

    var body: some View {
        Group {
            if let selectableCommits {
                CirclesWithArrows(
                    numberOfCircles: isCurrent ? selectableCommits.count + 1 : selectableCommits.count,
                    circleSize: BranchView.commitNodeSize,
                    spacing: 12
                ) { index in
                    BranchGraphContentView(
                        index: index,
                        isCurrent: isCurrent,
                        selectableStatus: selectableStatus,
                        selectableCommits: selectableCommits,
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected
                    )
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .task {
            selectableCommits = await branchInfo.commits()
        }
    }
}
