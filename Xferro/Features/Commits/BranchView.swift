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
                CirclesWithArrows(numberOfCircles: isCurrentBranch ? commits.count + 1 : commits.count) { index in
                    Group {
                        if isCurrentBranch && index == 0 {
                            Rectangle()
                                .fill(Color.green.opacity(0.8))
                                .cornerRadius(12)
                                .overlay {
                                    Text("Status")
                                        .font(.caption)
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                }
                        } else {
                            let offSet = isCurrentBranch ? 1 : 0
                            FlaredRounded(backgroundColor: isCurrentBranch && index - offSet == 0 ? .red.opacity(0.3) : Color(hex: 0x232834).opacity(0.8)) {
                                ZStack {
                                    Text(commits[index - offSet].oid.debugOID.prefix(4))
                                        .font(.caption)
                                        .foregroundColor(Color.fabulaFore1)
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                }
                            }
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 2)
                            .frame(width: 34, height: 34)
                    }
                }
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
