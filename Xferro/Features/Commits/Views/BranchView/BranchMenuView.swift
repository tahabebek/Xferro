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
    @State var showingMergeTargetBranchSheet = false
    @State var showingRebaseTargetBranchSheet = false

    let remotes: [Remote]
    let isCurrent: Bool
    let name: String
    let isDetached: Bool
    let branchCount: Int
    let localBranches: [String]
    let remoteBranches: [String]
    let currentBranch: String

    let onDeleteBranchTapped: (String) -> Void
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void
    let onMergeOrRebase: (String, String, BranchOperationView.OperationType) -> Void

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
                showingMergeTargetBranchSheet: $showingMergeTargetBranchSheet,
                showingRebaseTargetBranchSheet: $showingRebaseTargetBranchSheet,
                remotes: remotes,
                isCurrent: isCurrent,
                name: name,
                isDetached: isDetached,
                branchCount: branchCount,
                onDeleteBranchTapped: onDeleteBranchTapped,
                onCheckoutBranchTapped: { onCheckoutOrDelete($0, false, .checkout) },
                onTapPush: onTapPush,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onAddRemoteTapped: onAddRemoteTapped
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
        .sheet(isPresented: $showingMergeTargetBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .merge(target: nil, destination: name)
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $showingRebaseTargetBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .rebase(target: nil, destination: name)
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
    }
}
