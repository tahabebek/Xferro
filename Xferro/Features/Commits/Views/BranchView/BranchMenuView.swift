//
//  BranchMenuView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchMenuView: View {
    @State var showingBranchOptions = false
    @State var showingCheckoutBranchSheet = false
    @State var showingCreateBranchSheet = false
    @State var showingDeleteBranchSheet = false
    @State var showingMergeSourceBranchSheet = false
    @State var showingMergeTargetBranchSheet = false
    @State var showingRebaseSourceBranchSheet = false
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
                showingCheckoutBranchSheet: $showingCheckoutBranchSheet,
                showingDeleteBranchSheet: $showingDeleteBranchSheet,
                showingMergeSourceBranchSheet: $showingMergeSourceBranchSheet,
                showingMergeTargetBranchSheet: $showingMergeTargetBranchSheet,
                showingRebaseSourceBranchSheet: $showingRebaseSourceBranchSheet,
                showingRebaseTargetBranchSheet: $showingRebaseTargetBranchSheet,
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
        .sheet(isPresented: $showingDeleteBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .delete
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $showingMergeSourceBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .merge(currentBranch, nil)
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $showingMergeSourceBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .merge(nil, currentBranch)
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $showingRebaseSourceBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .rebase(currentBranch, nil)
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $showingRebaseSourceBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .rebase(nil, currentBranch)
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $showingCheckoutBranchSheet) {
            BranchOperationView(
                localBranches: localBranches,
                remoteBranches: remoteBranches,
                onCheckoutOrDelete: onCheckoutOrDelete,
                onMergeOrRebase: onMergeOrRebase,
                currentBranch: currentBranch,
                operation: .checkout
            )
            .padding()
            .frame(maxHeight: .infinity)
        }
    }
}
