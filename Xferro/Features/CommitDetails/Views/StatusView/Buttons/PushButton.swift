//
//  PushButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct PushButton: View {
    var commitSummary: Binding<String>?
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @Binding var selectedRemoteForPush: Remote?
    @State var options: [XFButtonOption<Remote>] = []

    let remotes: [Remote]
    let title: String
    let amend: Bool
    let force: Bool
    let pushOnly: Bool

    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onAmendAndForcePushWithLease: ((Remote?) -> Void)?
    let onAmendAndPush: ((Remote?) -> Void)?
    let onCommitAndForcePushWithLease: ((Remote?) -> Void)?
    let onCommitAndPush: ((Remote?) -> Void)?
    let onPush: ((Remote?) -> Void)?
    let onForcePushWithLease: ((Remote?) -> Void)?

    init(
        commitSummary: Binding<String>? = nil,
        canCommit: Binding<Bool> = .constant(true),
        hasChanges: Binding<Bool> = .constant(true),
        selectedRemoteForPush: Binding<Remote?>,
        remotes: [Remote],
        title: String,
        amend: Bool = false,
        force: Bool = false,
        pushOnly: Bool = false,
        onGetLastSelectedRemoteIndex: @escaping (String) -> Int,
        onSetLastSelectedRemoteIndex: @escaping (Int, String) -> Void,
        onAddRemoteTapped: @escaping () -> Void,
        onAmendAndForcePushWithLease: ((Remote?) -> Void)? = nil,
        onAmendAndPush: ((Remote?) -> Void)? = nil,
        onCommitAndForcePushWithLease: ((Remote?) -> Void)? = nil,
        onCommitAndPush: ((Remote?) -> Void)? = nil,
        onPush: ((Remote?) -> Void)? = nil,
        onForcePushWithLease: ((Remote?) -> Void)? = nil
    ) {
        self.commitSummary = commitSummary
        self._canCommit = canCommit
        self._hasChanges = hasChanges
        self._selectedRemoteForPush = selectedRemoteForPush
        self.remotes = remotes
        self.title = title
        self.amend = amend
        self.force = force
        self.pushOnly = pushOnly
        self.onGetLastSelectedRemoteIndex = onGetLastSelectedRemoteIndex
        self.onSetLastSelectedRemoteIndex = onSetLastSelectedRemoteIndex
        self.onAddRemoteTapped = onAddRemoteTapped
        self.onAmendAndForcePushWithLease = onAmendAndForcePushWithLease
        self.onAmendAndPush = onAmendAndPush
        self.onCommitAndForcePushWithLease = onCommitAndForcePushWithLease
        self.onCommitAndPush = onCommitAndPush
        self.onPush = onPush
        self.onForcePushWithLease = onForcePushWithLease

        self._options = State(wrappedValue: remotes.map { XFButtonOption(title: $0.name!, data: $0) })
    }

    var body: some View {
        XFButton<Remote,Text>(
            title: title,
            info: force ? XFButtonInfo(info: InfoTexts.forcePushWithLease) : XFButtonInfo(info: InfoTexts.push),
            disabled: ((commitSummary?.wrappedValue.isEmptyOrWhitespace ?? false) || !hasChanges) && !amend,
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
                if pushOnly {
                    if force {
                        onForcePushWithLease?(selectedRemoteForPush)
                    } else {
                        onPush?(selectedRemoteForPush)
                    }
                } else {
                    if amend {
                        if force {
                            onAmendAndForcePushWithLease?(selectedRemoteForPush)
                        } else {
                            onAmendAndPush?(selectedRemoteForPush)
                        }
                    } else {
                        if force {
                            onCommitAndForcePushWithLease?(selectedRemoteForPush)
                        } else {
                            onCommitAndPush?(selectedRemoteForPush)
                        }
                    }
                }
            }
        )
        .onChange(of: remotes.count) {
            options = remotes.map { XFButtonOption(title: $0.name!, data: $0) }
        }
        .task {
            let index = onGetLastSelectedRemoteIndex("push")
            if index < remotes.count {
                selectedRemoteForPush = remotes[index]
            }
        }
    }
}
