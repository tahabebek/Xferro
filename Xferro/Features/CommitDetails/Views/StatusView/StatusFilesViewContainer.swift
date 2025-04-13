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

    let onCommitTapped: () -> Void
    let onTapExcludeAll: () -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (OldNewFile) -> Void
    let onTapUntrack: (OldNewFile) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

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
    let onTapPush: (Remote?) -> Void
    let onTapForcePushWithLease: (Remote?) -> Void

    var body: some View {
        VStack {
            StatusActionView(
                commitSummary: $commitSummary,
                canCommit: $canCommit,
                hasChanges: $hasChanges,
                remotes: remotes,
                stashes: stashes,
                onCommitTapped: {
                    onCommitTapped()
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
            .padding(.vertical)
            .background(Color(hexValue: 0x15151A))
            .cornerRadius(8)
            if hasChanges {
                StatusViewChangeView(
                    currentFile: $currentFile,
                    trackedFiles: $trackedFiles,
                    untrackedFiles: $untrackedFiles,
                    onTapExcludeAll: onTapExcludeAll,
                    onTapIncludeAll: onTapIncludeAll,
                    onTapTrack: onTapTrack,
                    onTapUntrack: onTapUntrack,
                    onTapTrackAll: onTapTrackAll,
                    onTapIgnore: onTapIgnore,
                    onTapDiscard: onTapDiscard
                )
            } else {
                StatusViewNoChangeView(
                    remotes: remotes,
                    onTapPush: onTapPush,
                    onTapForcePushWithLease: onTapForcePushWithLease,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped
                )
            }
        }
        .animation(.default, value: hasChanges)
    }
}
