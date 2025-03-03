//
//  BranchCommitCircleView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchCommitCircleView: View {
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?
    let selectableCommits: [any BranchItem]
    let isCurrent: Bool
    let index: Int

    var body: some View {
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
