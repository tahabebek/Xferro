//
//  DetachedCommitBranchGraphView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import SwiftUI

struct DetachedCommitBranchGraphView: View {
    @State var selectableCommits: [SelectableDetachedCommit]?
    let detachedCommitInfo: DetachedCommitInfo
    let selectableStatus: SelectableStatus
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?

    var body: some View {
        Group {
            if let selectableCommits {
                CirclesWithArrows(
                    numberOfCircles: selectableCommits.count + 1,
                    circleSize: BranchView.commitNodeSize,
                    spacing: 12
                ) { index in
                    BranchGraphContentView(
                        index: index,
                        isCurrent: true,
                        selectableStatus: selectableStatus,
                        selectableCommits: selectableCommits,
                        onUserTapped: onUserTapped,
                        onIsSelected: onIsSelected
                    )
                }
            } else {
                ProgressView()
            }
        }
        .task {
            selectableCommits = await detachedCommitInfo.commits()
        }
    }
}
