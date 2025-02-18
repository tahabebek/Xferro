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
    static let commitNodeSize: CGFloat = 54
    @Environment(CommitsViewModel.self) var viewModel
    let name: String
    let selectableCommits: [any BranchItem]
    let selectableStatus: SelectableStatus
    let isCurrent: Bool
    let isDetached: Bool
    let branchCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                menu
                    .frame(maxWidth: 120)
                    .padding(.trailing, 8)
                graph
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var graph: some View {
        CirclesWithArrows(
            numberOfCircles: isCurrent ? selectableCommits.count + 1 : selectableCommits.count,
            circleSize: Self.commitNodeSize,
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
                            viewModel.userTapped(item: selectableStatus)
                        }
                        .frame(width: Self.commitNodeSize, height: Self.commitNodeSize)
                    if viewModel.isSelected(item: selectableStatus) {
                        SelectedItemOverlay(width: Self.commitNodeSize, height: Self.commitNodeSize)
                    }
                } else {
                    let offset = isCurrent ? 1 : 0
                    let item = selectableCommits[index - offset]
                    FlaredRounded(backgroundColor: Color(hex: 0x232834).opacity(0.7)) {
                        ZStack {
                            Text(selectableCommits[index - offset].commit.summary)
                                .font(.caption)
                                .minimumScaleFactor(0.9)
                                .allowsTightening(true)
                                .padding(6)
                                .lineLimit(4)
                                .foregroundColor(Color.fabulaFore1)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .onTapGesture {
                        viewModel.userTapped(item: item)
                    }
                    if viewModel.isSelected(item: item) {
                        SelectedItemOverlay(width: Self.commitNodeSize, height: Self.commitNodeSize)
                    }
                }
            }
        }
    }

    private var menu : some View {
        Menu {
            if !isCurrent {
                Button {
                    fatalError()
                } label: {
                    Text("Switch to \(name)")
                }
                if !isDetached {
                    Button {
                        viewModel.deleteBranchTapped(repository: selectableStatus.repository, branchName: name)
                    } label: {
                        Text("Delete \(name)")
                    }
                }
            }
            Button {
                fatalError()
            } label: {
                Text("Create a new branch based on \(name)")
            }
            if !isDetached, branchCount > 1 {
                Button {
                    fatalError()
                } label: {
                    Text("Merge a branch into \(name)")
                }
                Button {
                    fatalError()
                } label: {
                    Text("Rebase a branch into \(name)")
                }
                Button {
                    fatalError()
                } label: {
                    Text("Merge \(name) into another branch")
                }
                Button {
                    fatalError()
                } label: {
                    Text("Rebase \(name) into another branch")
                }
            }
        } label: {
            Text(name)
                .font(.caption)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .cornerRadius(4)
                .lineLimit(1)
                .alignmentGuide(.verticalAlignment, computeValue: { d in
                    d[VerticalAlignment.center] }
                )
        }
        .truncationMode(.middle)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentColor, lineWidth: isCurrent ? 1 : 0)
        }
    }
}
