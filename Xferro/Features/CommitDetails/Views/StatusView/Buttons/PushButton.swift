//
//  PushButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct PushButton: View {
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @Binding var selectedRemoteForPush: Remote?
    @Binding var errorString: String?
    @State var options: [XFButtonOption<Remote>] = []

    let remotes: [Remote]
    let title: String
    let amend: Bool
    let force: Bool

    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onAmendAndForcePushWithLease: (Remote?) async throws -> Void
    let onAmendAndPush: (Remote?) async throws -> Void
    let onCommitAndForcePushWithLease: (Remote?) async throws -> Void
    let onCommitAndPush: (Remote?) async throws -> Void

    init(
        commitSummary: Binding<String>,
        canCommit: Binding<Bool>,
        hasChanges: Binding<Bool>,
        selectedRemoteForPush: Binding<Remote?> = .constant(nil),
        errorString: Binding<String?> = .constant(nil),
        remotes: [Remote],
        title: String,
        amend: Bool,
        force: Bool,
        onGetLastSelectedRemoteIndex: @escaping (String) -> Int,
        onSetLastSelectedRemoteIndex: @escaping (Int, String) -> Void,
        onAddRemoteTapped: @escaping () -> Void,
        onAmendAndForcePushWithLease: @escaping (Remote?) async throws -> Void,
        onAmendAndPush: @escaping (Remote?) async throws -> Void,
        onCommitAndForcePushWithLease: @escaping (Remote?) async throws -> Void,
        onCommitAndPush: @escaping (Remote?) async throws -> Void
    ) {
        self._commitSummary = commitSummary
        self._canCommit = canCommit
        self._hasChanges = hasChanges
        self._selectedRemoteForPush = selectedRemoteForPush
        self._errorString = errorString
        self.remotes = remotes
        self.title = title
        self.amend = amend
        self.force = force
        self.onGetLastSelectedRemoteIndex = onGetLastSelectedRemoteIndex
        self.onSetLastSelectedRemoteIndex = onSetLastSelectedRemoteIndex
        self.onAddRemoteTapped = onAddRemoteTapped
        self.onAmendAndForcePushWithLease = onAmendAndForcePushWithLease
        self.onAmendAndPush = onAmendAndPush
        self.onCommitAndForcePushWithLease = onCommitAndForcePushWithLease
        self.onCommitAndPush = onCommitAndPush

        self._options = State(wrappedValue: remotes.map { XFButtonOption(title: $0.name!, data: $0) })
    }

    var body: some View {
        XFButton<Remote>(
            title: title,
            info: force ? XFButtonInfo(info: InfoTexts.forcePushWithLease) : XFButtonInfo(info: InfoTexts.push),
            disabled: (commitSummary.isEmptyOrWhitespace || !hasChanges) && !amend,
            options: $options,
            selectedOptionIndex: Binding<Int>(
                get: {
                    onGetLastSelectedRemoteIndex("push")
                }, set: { value, _ in
                    onSetLastSelectedRemoteIndex(value, "push")
                }
            ),
            addMoreOptionsText: "Add Remote...",
            onTapOption: { option in
                selectedRemoteForPush = option.data
            },
            onTapAddMore: {
                onAddRemoteTapped()
            },
            onTap: {
                Task {
                    do {
                        if amend {
                            if force {
                                try await onAmendAndForcePushWithLease(selectedRemoteForPush)
                            } else {
                                try await onAmendAndPush(selectedRemoteForPush)
                            }
                        } else {
                            if force {
                                try await onCommitAndForcePushWithLease(selectedRemoteForPush)
                            } else {
                                try await onCommitAndPush(selectedRemoteForPush)
                            }
                        }
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
        .onChange(of: remotes.count) {
            options = remotes.map { XFButtonOption(title: $0.name!, data: $0) }
        }
        .task {
            selectedRemoteForPush = remotes[onGetLastSelectedRemoteIndex("push")]
        }
    }
}
