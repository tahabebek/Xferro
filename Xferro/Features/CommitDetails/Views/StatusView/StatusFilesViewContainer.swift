//
//  StatusFilesViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/13/25.
//

import SwiftUI

struct StatusFilesViewContainer: View {
    @Binding var currentFile: OldNewFile?
    @Binding var trackedFiles: [OldNewFile]
    @Binding var untrackedFiles: [OldNewFile]
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    let remotes: [Remote]
    let stashes: [SelectableStash]

    let onCommitTapped: () async throws -> Void
    let onTapExcludeAll: () -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (OldNewFile) -> Void
    let onTapUntrack: (OldNewFile) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

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
        VStack {
            StatusActionView(
                commitSummary: $commitSummary,
                canCommit: $canCommit,
                hasChanges: $hasChanges,
                remotes: remotes,
                stashes: stashes,
                onCommitTapped: {
                    try await onCommitTapped()
                    Task { @MainActor in
                        currentFile = nil
                    }
                },
                onAmend: onAmend,
                onApplyStash: onApplyStash,
                onStash: onStash,
                onDiscardAll: onDiscardAll,
                onPopStash: onPopStash,
                onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                onAddRemoteTapped: onAddRemoteTapped,
                onAmendAndForcePushWithLease: onAmendAndForcePushWithLease,
                onAmendAndPush: onAmendAndPush,
                onCommitAndForcePushWithLease: onCommitAndForcePushWithLease,
                onCommitAndPush: onCommitAndPush
            )
            .padding()
            .background(Color(hexValue: 0x15151A))
            .cornerRadius(8)
            StatusViewChangeView(
                currentFile: $currentFile,
                trackedFiles: $trackedFiles,
                untrackedFiles: $untrackedFiles,
                hasChanges: $hasChanges,
                onTapExcludeAll: onTapExcludeAll,
                onTapIncludeAll: onTapIncludeAll,
                onTapTrack: onTapTrack,
                onTapUntrack: onTapUntrack,
                onTapTrackAll: onTapTrackAll,
                onTapIgnore: onTapIgnore,
                onTapDiscard: onTapDiscard
            )
        }
    }
}
