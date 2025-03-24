//
//  RepositoryViewMenu.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryMenuView: View {
    @Binding var isCollapsed: Bool
    @State var showButtons = false
    @State var selectedRemoteForFetch: Remote?
    @State var options: [XFButtonOption<Remote>] = []

    let onDeleteRepositoryTapped: () -> Void
    let onPullTapped: (StatusViewModel.PullType) -> Void
    let onFetchTapped: (StatusViewModel.FetchType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void

    let gitDir: URL
    let head: Head
    let remotes: [Remote]
    let isSelected: Bool

    init(
        isCollapsed: Binding<Bool>,
        onDeleteRepositoryTapped: @escaping () -> Void,
        onPullTapped: @escaping (StatusViewModel.PullType) -> Void,
        onFetchTapped: @escaping  (StatusViewModel.FetchType) -> Void,
        onAddRemoteTapped: @escaping  () -> Void,
        onGetLastSelectedRemoteIndex: @escaping (String) -> Int,
        onSetLastSelectedRemote: @escaping (Int, String) -> Void,
        gitDir: URL,
        head: Head,
        remotes: [Remote],
        isSelected: Bool
    ) {
        self._isCollapsed = isCollapsed
        self.onDeleteRepositoryTapped = onDeleteRepositoryTapped
        self.onPullTapped = onPullTapped
        self.onFetchTapped = onFetchTapped
        self.onAddRemoteTapped = onAddRemoteTapped
        self.onGetLastSelectedRemoteIndex = onGetLastSelectedRemoteIndex
        self.onSetLastSelectedRemote = onSetLastSelectedRemote
        self.gitDir = gitDir
        self.head = head
        self.remotes = remotes
        self.isSelected = isSelected

        self._options = State(wrappedValue: remotes.map { XFButtonOption(title: $0.name!, data: $0) })
    }

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .font(.paragraph2)
                .foregroundColor(isSelected ? Color.accentColor : Color.white)
            Label(gitDir.deletingLastPathComponent().lastPathComponent,
                systemImage: Images.actionButtonSystemImageName)
                .foregroundColor(isSelected ? Color.accentColor : Color.white)
                .font(.paragraph2)
                .labelStyle(RightImageLabelStyle())
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture {
                    showButtons.toggle()
                }
                .popover(isPresented: $showButtons) {
                    buttons
                        .padding()
                }
            Spacer()
            RepositoryNavigationView(isCollapsed: $isCollapsed, deleteRepositoryTapped: onDeleteRepositoryTapped)
                .font(.accessoryButton)
        }
    }

    var buttons: some View {
        VStack(alignment: .leading, spacing: 8){
            XFButton<Remote>(
                title: "Fetch",
                info: XFButtonInfo(info: InfoTexts.fetch),
                options: $options,
                selectedOptionIndex: Binding<Int>(
                    get: {
                        return onGetLastSelectedRemoteIndex("push")
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
                title: "Create new branch",
                info: XFButtonInfo(info: InfoTexts.branch),
                onTap: {
                    showButtons = false
                    fatalError(.unimplemented)
                }
            )
            XFButton<Void>(
                title: "Create and check out to a new branch",
                onTap: {
                    showButtons = false
                    fatalError(.unimplemented)
                }
            )
            XFButton<Void>(
                title: "Chekout to a remote branch",
                onTap: {
                    showButtons = false
                    fatalError(.unimplemented)
                }
            )
            Divider()
            XFButton<Void>(
                title: "Create new tag",
                info: XFButtonInfo(info: InfoTexts.tag),
                onTap: {
                    showButtons = false
                    fatalError(.unimplemented)
                }
            )
        }
    }
}
