//
//  BranchMenuPopover.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import SwiftUI

struct BranchMenuPopover: View {
    @Binding var showingBranchOptions: Bool
    @Binding var showingCreateBranchSheet: Bool
    @Binding var showingCheckoutBranchSheet: Bool
    @Binding var showingDeleteBranchSheet: Bool
    @Binding var showingMergeSourceBranchSheet: Bool
    @Binding var showingMergeTargetBranchSheet: Bool
    @Binding var showingRebaseSourceBranchSheet: Bool
    @Binding var showingRebaseTargetBranchSheet: Bool
    @State var selectedRemoteForPush: Remote?

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
        VStack(alignment: .leading, spacing: 8) {
            if !isCurrent {
                XFButton<Void>(
                    title: "Checkout to \(name)",
                    onTap: {
                        showingBranchOptions = false
                        showingCheckoutBranchSheet = true
                    }
                )
            }
            PushButton(
                selectedRemoteForPush: $selectedRemoteForPush,
                remotes: remotes,
                title: "Push",
                pushOnly: true,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onAddRemoteTapped: onAddRemoteTapped,
                onPush: {
                    onTapPush(name, $0, .normal)
                }
            )
            PushButton(
                selectedRemoteForPush: $selectedRemoteForPush,
                remotes: remotes,
                title: "Force Push with Lease",
                force: true,
                pushOnly: true,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onAddRemoteTapped: onAddRemoteTapped,
                onForcePushWithLease: {
                    onTapPush(name, $0, .forceWithLease)
                }
            )
            Divider()
            XFButton<Void>(
                title: "Create a new branch based on \(name)",
                onTap: {
                    showingBranchOptions = false
                    showingCreateBranchSheet = true
                }
            )

            if !isDetached, branchCount > 1 {
                Divider()
                XFButton<Void>(
                    title: "Merge a branch into \(name)",
                    onTap: {
                        showingBranchOptions = false
                        showingMergeSourceBranchSheet = true
                        fatalError(.unimplemented)
                    }
                )
                XFButton<Void>(
                    title: "Merge \(name) into another branch",
                    onTap: {
                        showingBranchOptions = false
                        showingMergeTargetBranchSheet = true
                    }
                )
                Divider()
                XFButton<Void>(
                    title: "Rebase a branch into \(name)",
                    onTap: {
                        showingBranchOptions = false
                        showingRebaseSourceBranchSheet = true
                    }
                )
                XFButton<Void>(
                    title: "Rebase \(name) into another branch",
                    onTap: {
                        showingBranchOptions = false
                        showingRebaseTargetBranchSheet = true
                    }
                )
            }
            if !isDetached {
                Divider()
                XFButton<Void>(
                    title: "Delete \(name)",
                    onTap: {
                        showingBranchOptions = false
                        showingDeleteBranchSheet = true
                    }
                )
            }
        }
    }
}
