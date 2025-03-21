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
    let remotes: [Remote]
    let stashes: [SelectableStash]
    @Binding var errorString: String?
    @State var selectedRemoteForPush: Remote?
    @State var selectedStashToApply: SelectableStash?

    let onAmend: () async throws -> Void
    let onApplyStash: (SelectableStash) async throws -> Void
    let onStash: () async throws -> Void
    let onDiscardAll: () async throws -> Void
    let onPopStash: () async throws -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onAmendAndForcePushWithLease: (Remote?) async throws -> Void
    let onAmendAndPush: (Remote?) async throws -> Void
    let onCommitAndForcePushWithLease: (Remote?) async throws -> Void
    let onCommitAndPush: (Remote?) async throws -> Void

    var body: some View {
        ForEach(boxActions) { boxAction in
            switch boxAction {
            case .amend:
                AmendButton(
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    errorString: $errorString,
                    title: boxAction.rawValue,
                    onAmend: onAmend
                )
            case .commitAndPush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: false,
                    force: false,
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
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: true,
                    force: false,
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
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: false,
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
                    errorString: $errorString,
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
                    errorString: $errorString,
                    title: boxAction.rawValue,
                    onStash: onStash
                )
            case .popStash:
                PopStashButton(
                    stashes: stashes,
                    errorString: $errorString,
                    title: boxAction.rawValue,
                    onPopStash: onPopStash
                )
            case .applyStash:
                ApplyStashButton(
                    selectedStashToApply: $selectedStashToApply,
                    errorString: $errorString,
                    title: boxAction.rawValue,
                    stashes: stashes,
                    onApplyStash: onApplyStash
                )
            case .discardAll:
                DiscardAllButton(
                    hasChanges: $hasChanges,
                    errorString: $errorString,
                    title: boxAction.rawValue,
                    onDiscardAll: onDiscardAll
                )
            }
        }
        .animation(.default, value: boxActions)
    }
}
