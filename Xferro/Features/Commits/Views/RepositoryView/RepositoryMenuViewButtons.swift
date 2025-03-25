//
//  RepositoryMenuViewButtons.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

struct RepositoryMenuViewButtons: View {
    @Binding var options: [XFButtonOption<Remote>]
    @Binding var selectedRemoteForFetch: Remote?
    @Binding var showButtons: Bool

    let remotes: [Remote]
    let head: Head

    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onPullTapped: (Repository.PullType) -> Void
    let onCreateBranchTapped: () -> Void
    let onCheckoutBranchTapped: () -> Void
    let onCreateTagTapped: () -> Void
    let onDeleteBranchTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            XFButton<Remote>(
                title: "Fetch",
                info: XFButtonInfo(info: InfoTexts.fetch),
                options: $options,
                selectedOptionIndex: Binding<Int>(
                    get: {
                        onGetLastSelectedRemoteIndex("push")
                    }, set: { value, _ in
                        onSetLastSelectedRemote(value, "push")
                    }
                ),
                addMoreOptionsText: "Add Remote...",
                onTapOption: { option in
                    selectedRemoteForFetch = option.data
                },
                onTapAddMore: {
                    onAddRemoteTapped()
                },
                onTap: {
                    showButtons = false
                    onFetchTapped(.remote(selectedRemoteForFetch))
                }
            )
            .onChange(of: remotes.count) {
                options = remotes.map { XFButtonOption(title: $0.name!, data: $0) }
            }
            .task {
                selectedRemoteForFetch = remotes[onGetLastSelectedRemoteIndex("push")]
            }
            XFButton<Void>(
                title: "Fetch all remotes (origin, upstream, etc.)",
                info: XFButtonInfo(info: InfoTexts.fetch),
                onTap: {
                    showButtons = false
                    onFetchTapped(.all)
                }
            )
            Divider()
            XFButton<Void>(
                title: "Pull \(head.name) branch (merge)",
                info: XFButtonInfo(info: InfoTexts.pull),
                onTap: {
                    showButtons = false
                    onPullTapped(.merge)
                }
            )
            XFButton<Void>(
                title: "Pull \(head.name) branch (rebase)",
                info: XFButtonInfo(info: InfoTexts.pull),
                onTap: {
                    showButtons = false
                    onPullTapped(.rebase)
                }
            )
            Divider()
            XFButton<Void>(
                title: "Checkout to a branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    onCheckoutBranchTapped()
                }
            )
            XFButton<Void>(
                title: "Create a new branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    onCreateBranchTapped()
                }
            )
            XFButton<Void>(
                title: "Delete a branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    onDeleteBranchTapped()
                }
            )
            Divider()
            XFButton<Void>(
                title: "Create a new tag",
                info: XFButtonInfo(info: InfoTexts.tag),
                onTap: {
                    showButtons = false
                    onCreateTagTapped()
                }
            )
        }
    }
}
