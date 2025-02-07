//
//  BranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct BranchView: View {
    @Environment(CommitsViewModel.self) var viewModel
    let branch: Branch
    let selectableCommits: [CommitsViewModel.SelectableCommit]
    let selectableStatus: CommitsViewModel.SelectableStatus
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
                CirclesWithArrows(numberOfCircles: isCurrentBranch ? selectableCommits.count + 1 : selectableCommits.count) { index in
                    ZStack {
                        if isCurrentBranch && index == 0 {
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .cornerRadius(12)
                                .overlay {
                                    Text("Status")
                                        .font(.caption)
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                }
                                .onTapGesture {
                                    viewModel.userTapped(item: selectableStatus)
                                }
                            if viewModel.isSelected(item: selectableStatus) {
                                SelectedItemOverlay()
                            }
                        } else {
                            let offset = isCurrentBranch ? 1 : 0
                            let item = self.selectableCommits[index - offset]
                            FlaredRounded(backgroundColor: isCurrentBranch && index - offset == 0 ? .red.opacity(0.3) : Color(hex: 0x232834).opacity(0.8)) {
                                ZStack {
                                    Text(selectableCommits[index - offset].commit.oid.debugOID.prefix(4))
                                        .font(.caption)
                                        .foregroundColor(Color.fabulaFore1)
                                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                }
                            }
                            .onTapGesture {
                                viewModel.userTapped(item: item)
                            }
                            if viewModel.isSelected(item: item) {
                                SelectedItemOverlay()
                            }
                        }
                    }
                    .overlay {
                        
                    }
                }
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
