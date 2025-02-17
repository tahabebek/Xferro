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
    let isCurrent: Bool
    let isDetached: Bool
    let branchCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .verticalAlignment) {
                menu
                    .frame(maxWidth: 120)
                graph
            }
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var graph: some View {
        CirclesWithArrows(numberOfCircles: isCurrent ? selectableCommits.count + 1 : selectableCommits.count) { index in
            ZStack {
                if isCurrent && index == 0 {
                    Circle()
                        .fill(Color.accentColor.opacity(0.7))
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
                    let item = selectableCommits[index - offset]
                    FlaredCircle(backgroundColor: Color(hex: 0x232834).opacity(0.8)) {
                        ZStack {
                            Text(selectableCommits[index - offset].commit.oid.debugOID.prefix(4))
                                .font(.caption)
                                .foregroundColor(Color.fabulaFore1)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .hoverableButton(item.commit.summary) {
                        viewModel.userTapped(item: item)
                    }
                    if viewModel.isSelected(item: item) {
                        SelectedItemOverlay()
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
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .background(isCurrent ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                .cornerRadius(4)
                .lineLimit(1)
                .alignmentGuide(.verticalAlignment, computeValue: { d in
                    d[VerticalAlignment.center] }
                )
        }
        .truncationMode(.middle)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }
}
