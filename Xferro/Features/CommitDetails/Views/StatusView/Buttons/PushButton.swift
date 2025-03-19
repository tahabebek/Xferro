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
    let remotes: [Remote]
    @Binding var selectedRemoteForPush: Remote?
    @Binding var errorString: String?

    let title: String
    let amend: Bool
    let force: Bool

    var body: some View {
        let remoteOptions: [XFerroButtonOption<Remote>] = remotes
            .compactMap { $0.name != nil ? XFerroButtonOption(title: $0.name!, data: $0) : nil }

        XFerroButton<Remote>(
            title: title,
            disabled: commitSummary.isEmptyOrWhitespace || !hasChanges,
            dangerous: force,
            options: remoteOptions,
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
        .task {
            selectedRemoteForPush = remotes[statusViewModel.getLastSelectedRemoteIndex(buttonTitle: "push")]
        }
    }
}
