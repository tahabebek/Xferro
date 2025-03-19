//
//  PushButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct PushButton: View {
    @Environment(StatusViewModel.self) var statusViewModel

    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @Binding var selectedRemoteForPush: Remote?
    @Binding var errorString: String?
    @State var options: [XFerroButtonOption<Remote>] = []

    let remotes: [Remote]
    let title: String
    let amend: Bool
    let force: Bool

    init(
        commitSummary: Binding<String>,
        canCommit: Binding<Bool>,
        hasChanges: Binding<Bool>,
        selectedRemoteForPush: Binding<Remote?> = .constant(nil),
        errorString: Binding<String?> = .constant(nil),
        remotes: [Remote],
        title: String,
        amend: Bool,
        force: Bool
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

        self._options = State(wrappedValue: remotes.map { XFerroButtonOption(title: $0.name!, data: $0) })
    }

    var body: some View {
        XFerroButton<Remote>(
            title: title,
            disabled: (commitSummary.isEmptyOrWhitespace || !hasChanges) && !amend,
            dangerous: force,
            options: $options,
            selectedOptionIndex: Binding<Int>(
                get: {
                    statusViewModel.getLastSelectedRemoteIndex(buttonTitle: "push")
                }, set: { value, _ in
                    statusViewModel.setLastSelectedRemote(value, buttonTitle: "push")
                }
            ),
            addMoreOptionsText: "Add Remote...",
            showsSearchOptions: false,
            onTapOption: { option in
                selectedRemoteForPush = option.data
            },
            onTapAddMore: {
                Task {
                    do {
                        try await statusViewModel.addRemoteTapped()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            },
            onTap: {
                Task {
                    do {
                        if amend {
                            if force {
                                try await statusViewModel.onAmendAndForcePush(remote: selectedRemoteForPush)
                            } else {
                                try await statusViewModel.onAmendAndPush(remote: selectedRemoteForPush)
                            }
                        } else {
                            if force {
                                try await statusViewModel.onCommitAndForcePush(remote: selectedRemoteForPush)
                            } else {
                                try await statusViewModel.onCommitAndPush(remote: selectedRemoteForPush)
                            }
                        }
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
        .onChange(of: remotes.count) {
            options = remotes.map { XFerroButtonOption(title: $0.name!, data: $0) }
        }
        .task {
            selectedRemoteForPush = remotes[statusViewModel.getLastSelectedRemoteIndex(buttonTitle: "push")]
        }
    }
}
