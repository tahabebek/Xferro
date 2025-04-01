//
//  StatusActionButtonsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusActionButtonsView: View {
    enum BoxAction: String, CaseIterable, Identifiable, Equatable {
        var id: String { rawValue }
        case addCommit = "Add Commit"
        case addWipCommit = "Add Wip Commit"
        case amend = "Amend"
        case commitAndPush = "Commit and Push"
        case amendAndPush = "Amend and Push"
        case commitAndForcePush = "Commit and Force Push with Lease"
        case amendAndForcePush = "Amend and Force Push with Lease"
        case stash = "Push Stash"
        case popStash = "Pop Stash"
        case applyStash = "Apply Stash"
        case discardAll = "Discard All Changes"
    }
    
    @State private var boxActions: [BoxAction] = BoxAction.allCases
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @State var selectedRemoteForPush: Remote?
    @State var selectedStashToApply: SelectableStash?

    let remotes: [Remote]
    let stashes: [SelectableStash]
    
    let onAddCommit: () -> Void
    let onAddWipCommit: (String) -> Void
    let onAmend: () -> Void
    let onApplyStash: (SelectableStash) -> Void
    let onStash: () -> Void
    let onDiscardAll: () -> Void
    let onPopStash: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onAmendAndForcePushWithLease: (Remote?) -> Void
    let onAmendAndPush: (Remote?) -> Void
    let onCommitAndForcePushWithLease: (Remote?) -> Void
    let onCommitAndPush: (Remote?) -> Void

    var body: some View {
        ForEach(boxActions) { boxAction in
            switch boxAction {
            case .addCommit:
                AddCommitButton(
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    commitSummary: $commitSummary,
                    title: boxAction.rawValue,
                    onAddCommit: onAddCommit
                )
            case .addWipCommit:
                AddWipCommitButton(
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    commitSummary: $commitSummary,
                    title: boxAction.rawValue,
                    onAddWipCommit: onAddWipCommit
                )
            case .amend:
                AmendButton(
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    title: boxAction.rawValue,
                    onAmend: onAmend
                )
            case .commitAndPush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onAmendAndForcePushWithLease: onAmendAndForcePushWithLease,
                    onAmendAndPush: onAmendAndPush,
                    onCommitAndForcePushWithLease: onCommitAndForcePushWithLease,
                    onCommitAndPush: onCommitAndPush
                )
            case .amendAndPush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: true,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onAmendAndForcePushWithLease: onAmendAndForcePushWithLease,
                    onAmendAndPush: onAmendAndPush,
                    onCommitAndForcePushWithLease: onCommitAndForcePushWithLease,
                    onCommitAndPush: onCommitAndPush
                )
            case .commitAndForcePush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    force: true,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onAmendAndForcePushWithLease: onAmendAndForcePushWithLease,
                    onAmendAndPush: onAmendAndPush,
                    onCommitAndForcePushWithLease: onCommitAndForcePushWithLease,
                    onCommitAndPush: onCommitAndPush
                )
            case .amendAndForcePush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: true,
                    force: true,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onAmendAndForcePushWithLease: onAmendAndForcePushWithLease,
                    onAmendAndPush: onAmendAndPush,
                    onCommitAndForcePushWithLease: onCommitAndForcePushWithLease,
                    onCommitAndPush: onCommitAndPush
                )
            case .stash:
                StashButton(
                    hasChanges: $hasChanges,
                    title: boxAction.rawValue,
                    onStash: onStash
                )
            case .popStash:
                PopStashButton(
                    stashes: stashes,
                    title: boxAction.rawValue,
                    onPopStash: onPopStash
                )
            case .applyStash:
                ApplyStashButton(
                    selectedStashToApply: $selectedStashToApply,
                    title: boxAction.rawValue,
                    stashes: stashes,
                    onApplyStash: onApplyStash
                )
            case .discardAll:
                DiscardAllButton(
                    hasChanges: $hasChanges,
                    title: boxAction.rawValue,
                    onDiscardAll: onDiscardAll
                )
            }
        }
        .animation(.default, value: boxActions)
    }
}
