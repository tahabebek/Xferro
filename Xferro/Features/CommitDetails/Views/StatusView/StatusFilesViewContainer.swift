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

    let onCommitTapped: () async throws -> Void
    let onBoxActionTapped: (StatusActionButtonsView.BoxAction) async -> Void
    let onTapExcludeAll: () -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (OldNewFile) -> Void
    let onTapUntrack: (OldNewFile) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

    var body: some View {
        VStack {
            StatusActionView(
                commitSummary: $commitSummary,
                canCommit: $canCommit,
                hasChanges: $hasChanges,
                onCommitTapped: {
                    try await onCommitTapped()
                    await MainActor.run {
                        currentFile = nil
                    }
                },
                onBoxActionTapped: onBoxActionTapped
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
