//
//  BranchMenuView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchMenuView: View {
    @Binding var showingBranchOptions: Bool
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
                remotes: remotes,
                isCurrent: isCurrent,
                name: name,
                isDetached: isDetached,
                branchCount: branchCount,
                onDeleteBranchTapped: onDeleteBranchTapped,
                onTapPush: onTapPush,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onAddRemoteTapped: onAddRemoteTapped
            )
            .padding()
        }
    }
}
