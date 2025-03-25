//
//  BranchMenuView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchMenuView: View {
    @State var showingBranchOptions = false
    @State var showingCreateBranchSheet = false
    let remotes: [Remote]
    let isCurrent: Bool
    let name: String
    let isDetached: Bool
    let branchCount: Int

    let onDeleteBranchTapped: (String) -> Void
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void

    var body: some View {
        Button(action: {
            showingBranchOptions = true
        }) {
            Label(name, systemImage: Images.actionButtonSystemImageName)
                .foregroundStyle(isCurrent ? Color.accentColor : Color.white)
                .fixedSize()
                .font(.paragraph4)
                .labelStyle(RightImageLabelStyle())
        }
        .buttonStyle(PlainButtonStyle())
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .background(Color.clear)
        .frame(minWidth: 40)
        .xfPopover(isPresented: $showingBranchOptions) {
            BranchMenuPopover(
                showingBranchOptions: $showingBranchOptions,
                showingCreateBranchSheet: $showingCreateBranchSheet,
                remotes: remotes,
                isCurrent: isCurrent,
                name: name,
                isDetached: isDetached,
                branchCount: branchCount,
                onDeleteBranchTapped: onDeleteBranchTapped,
                onTapPush: onTapPush,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onAddRemoteTapped: onAddRemoteTapped,
                onCreateBranchTapped: onCreateBranchTapped
            )
            .padding()
        }
        .sheet(isPresented: $showingCreateBranchSheet) {
            AddNewBranchView(
                onCreateBranch: onCreateBranchTapped,
                preselectedLocalBranch: name
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
    }
}
