//
//  StatusActionView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusActionView: View {
    @FocusState private var isTextFieldFocused: Bool
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top

    let remotes: [Remote]
    let stashes: [SelectableStash]
    let onCommitTapped: () -> Void
    let onWipCommitTapped: (String) -> Void
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
        VStack {
            Form {
                TextField(
                    "",
                    text: $commitSummary,
                    prompt: Text("Summary"),
                    axis: .vertical
                )
                .font(.formField)
                .focused($isTextFieldFocused)
                .textFieldStyle(.roundedBorder)
            }
            .padding(.bottom, Dimensions.actionBoxBottomPadding)
            AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                StatusActionButtonsView(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    remotes: remotes,
                    stashes: stashes,
                    onAddCommit: {
                        onCommitTapped()
                        isTextFieldFocused = false
                    },
                    onAddWipCommit: {
                        onWipCommitTapped($0)
                        isTextFieldFocused = false
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
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
