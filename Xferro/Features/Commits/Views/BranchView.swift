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
    @Environment(CommitsViewModel.self) var viewModel
    let name: String
    let selectableCommits: [any BranchItem]
    let selectableStatus: SelectableStatus
    let isCurrent : Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                VStack(spacing: 0) {
                    Text(name)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(isCurrent ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                        .cornerRadius(4)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .frame(maxWidth: 160)
                        .lineLimit(1)
                        .alignmentGuide(.verticalAlignment, computeValue: { d in
                            d[VerticalAlignment.center] }
                        )
                }
                CirclesWithArrows(numberOfCircles: isCurrent ? selectableCommits.count + 1 : selectableCommits.count) { index in
                    ZStack {
                        if isCurrent && index == 0 {
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
                            let offset = isCurrent ? 1 : 0
                            let item = self.selectableCommits[index - offset]
                            FlaredRounded(backgroundColor: isCurrent && index - offset == 0 ? .red.opacity(0.3) : Color(hex: 0x232834).opacity(0.8)) {
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
                }
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
