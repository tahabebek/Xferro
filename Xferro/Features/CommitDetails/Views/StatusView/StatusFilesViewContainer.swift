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
    @State private var committing: Bool = false

    let onCommitTapped: () async throws -> Void
    let onBoxActionTapped: (StatusActionButtonsView.BoxAction) async -> Void
    let onTapExcludeAll: () -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (OldNewFile) -> Void
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
                    committing = true
                    try await onCommitTapped()
                    await MainActor.run {
                        committing = false
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
                onTapTrackAll: onTapTrackAll,
                onTapIgnore: onTapIgnore,
                onTapDiscard: onTapDiscard
            ).opacity(committing ? 0 : 1)
            ProgressView()
                .controlSize(.small)
                .opacity(committing ? 1 : 0)
        }
    }
}
