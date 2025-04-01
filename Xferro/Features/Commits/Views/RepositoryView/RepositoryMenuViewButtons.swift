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
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onPullTapped: (Repository.PullType) -> Void
    let onCreateBranchTapped: () -> Void
    let onCheckoutBranchTapped: () -> Void
    let onCreateTagTapped: () -> Void
    let onDeleteBranchTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            XFButton<Remote,Text>(
                title: "Fetch",
                info: XFButtonInfo(info: InfoTexts.fetch),
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
            XFButton<Void,Text>(
                title: "Fetch all remotes (origin, upstream, etc.)",
                info: XFButtonInfo(info: InfoTexts.fetch),
                onTap: {
                    showButtons = false
                    onFetchTapped(.all)
                }
            )
            Divider()
            XFButton<Void,Text>(
                title: "Pull \(head.name) branch with merge",
                info: XFButtonInfo(info: InfoTexts.pull),
                onTap: {
                    showButtons = false
                    onPullTapped(.merge)
                }
            )
            XFButton<Void,Text>(
                title: "Pull \(head.name) branch with rebase",
                info: XFButtonInfo(info: InfoTexts.pull),
                onTap: {
                    showButtons = false
                    onPullTapped(.rebase)
                }
            )
            Divider()
            XFButton<Void,Text>(
                title: "Checkout to a branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    onCheckoutBranchTapped()
                }
            )
            XFButton<Void,Text>(
                title: "Create a new branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    onCreateBranchTapped()
                }
            )
            XFButton<Void,Text>(
                title: "Delete a branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    onDeleteBranchTapped()
                }
            )
            Divider()
            XFButton<Void,Text>(
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
