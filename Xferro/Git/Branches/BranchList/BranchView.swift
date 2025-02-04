//
//  BranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct BranchView: View {
    let branch: Branch
    let commits: [Commit]
    let isCurrentBranch : Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                VStack(spacing: 0) {
                    Text(branch.name)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(isCurrentBranch ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                        .cornerRadius(4)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .frame(maxWidth: 160)
                        .lineLimit(1)
                        .alignmentGuide(.verticalAlignment, computeValue: { d in
                            d[VerticalAlignment.center] }
                        )
                }
                CirclesWithArrows(numberOfCircles: commits.count) { index in
                    FlaredCircle(backgroundColor: isCurrentBranch && index == 0 ? .red.opacity(0.3) : Color(hex: 0x232834).opacity(0.8)) {
                        Text(commits[index].oid.debugOID.prefix(4))
                            .foregroundColor(Color.fabulaFore1)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    }
                }
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
