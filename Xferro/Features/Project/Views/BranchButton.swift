//
//  BranchButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/31/25.
//

import SwiftUI

struct BranchButton: View {
    @Binding var branches: [BranchInfo]
    @State var showOtherActions: Bool = false
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
    let onPullTapped: (Repository.PullType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void
    let onMergeOrRebase: (String, String, BranchOperationView.OperationType) -> Void
    let onTapBranch: (BranchInfo) -> Void
    let onTapNewBranch: () -> Void

    var body: some View {
        XFButton<BranchInfo, Text>(
            title: "Current Branch",
            optionWidth: 100,
            options: Binding<[XFButtonOption<BranchInfo>]>(
                get: { branches.map( {
                    XFButtonOption(title: $0.branch.name, data: $0)
                })},
                set: { _ in }
            ),
            selectedOptionIndex: .constant(0),
            addMoreOptionsText: "New branch",
            onTapOption: {
                onTapBranch($0.data)
            },
            onTapAddMore: {
                onTapNewBranch()
            },
            onTap: {
                showOtherActions.toggle()
            },
            otherActionsTapped: {
                showOtherActions.toggle()
            }
        )
        .xfPopover(isPresented: $showOtherActions) {
            BranchMenuPopover(
                showingBranchOptions: $showOtherActions,
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
                onPullTapped: onPullTapped,
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

