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
                    Circle()
                        .fill(Color.accentColor.opacity(0.7))
                        .overlay {
                            Text("Status")
                                .font(.caption)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                        .onTapGesture {
                            onUserTapped?(selectableStatus)
                        }
                        .frame(width: BranchView.commitNodeSize, height: BranchView.commitNodeSize)
                    if onIsSelected?(selectableStatus) ?? false {
                        SelectedItemOverlay(width: BranchView.commitNodeSize, height: BranchView.commitNodeSize)
                    }
                } else {
                    let offset = isCurrent ? 1 : 0
                    let item = selectableCommits[index - offset]
                    FlaredCircle(backgroundColor: Color(hexValue: 0x232834).opacity(0.7)) {
                        ZStack {
                            Text(selectableCommits[index - offset].commit.summary)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.9)
                                .allowsTightening(true)
                                .padding(6)
                                .lineLimit(4)
                                .foregroundColor(Color.fabulaFore1)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .onTapGesture {
                        onUserTapped?(item)
                    }
                    if onIsSelected?(item) == false {
                        SelectedItemOverlay(width: BranchView.commitNodeSize, height: BranchView.commitNodeSize)
                    }
                }
            }
        }
    }
}
