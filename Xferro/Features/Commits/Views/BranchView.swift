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
    let viewModel: BranchViewModel
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
                            viewModel.onUserTapped(selectableStatus)
                        }
                        .frame(width: Self.commitNodeSize, height: Self.commitNodeSize)
                    if viewModel.onIsSelected(selectableStatus) {
                        SelectedItemOverlay(width: Self.commitNodeSize, height: Self.commitNodeSize)
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
                        viewModel.onUserTapped(item)
                    }
                    if viewModel.onIsSelected(item) {
                        SelectedItemOverlay(width: Self.commitNodeSize, height: Self.commitNodeSize)
                    }
                }
            }
        }
    }

    // Using a regular button instead since Menu doesn't respond to clicks
    @State private var showingBranchOptions = false
    
    private var menu: some View {
        Button(action: {
            print("Branch button tapped!")
            showingBranchOptions = true
        }) {
            Label(name, systemImage: "arrowtriangle.down.fill")
                .foregroundStyle(isCurrent ? Color.accentColor : Color.white)
                .fixedSize()
                .labelStyle(RightImageLabelStyle())
        }
        .buttonStyle(PlainButtonStyle())
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .background(Color.clear)
        .frame(minWidth: 40)
        .popover(isPresented: $showingBranchOptions) {
            VStack(alignment: .leading, spacing: 8) {
                if !isCurrent {
                    Button("Switch to \(name)") {
                        print("Switch to branch")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)
                    
                    if !isDetached {
                        Button("Delete \(name)") {
                            viewModel.onDeleteBranchTapped(name)
                            showingBranchOptions = false
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Button("Create a new branch based on \(name)") {
                    print("Create branch")
                    showingBranchOptions = false
                }
                .padding(.vertical, 4)
                
                if !isDetached, branchCount > 1 {
                    Divider()
                    
                    Button("Merge a branch into \(name)") {
                        print("Merge into")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)
                    
                    Button("Rebase a branch into \(name)") {
                        print("Rebase into")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)
                    
                    Button("Merge \(name) into another branch") {
                        print("Merge to")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)
                    
                    Button("Rebase \(name) into another branch") {
                        print("Rebase to")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .frame(minWidth: 250)
        }
    }
}
