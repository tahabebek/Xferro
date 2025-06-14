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
    @State var showCreateBranchSheet = false
    @State var showCheckoutBranchSheet = false
    @State var showCreateTagSheet = false
    @State var showDeleteBranchSheet = false

    let gitDir: URL
    let head: Head
    let remotes: [Remote]
    let isSelected: Bool
    let localBranchNames: [String]
    let remoteBranchNames: [String]

    let onDeleteRepositoryTapped: () -> Void
    let onPullTapped: (Repository.PullType) -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onCreateTagTapped: (String, String?, String, Bool) -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void

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
                .task {
                    options = remotes.map { XFButtonOption(title: $0.name!, data: $0) }
                }
                .xfPopover(isPresented: $showButtons) {
                    RepositoryMenuViewButtons(
                        options: $options,
                        selectedRemoteForFetch: $selectedRemoteForFetch,
                        showButtons: $showButtons,
                        remotes: remotes,
                        head: head,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                        onAddRemoteTapped: onAddRemoteTapped,
                        onFetchTapped: onFetchTapped,
                        onPullTapped: onPullTapped,
                        onCreateBranchTapped: {
                            showCreateBranchSheet = true
                        },
                        onCheckoutBranchTapped: {
                            showCheckoutBranchSheet = true
                        },
                        onCreateTagTapped: {
                            showCreateTagSheet = true
                        },
                        onDeleteBranchTapped: {
                            showDeleteBranchSheet = true
                        }
                    )
                    .padding()
                }
                .sheet(isPresented: $showCreateBranchSheet) {
                    AddNewBranchView(
                        localBranches: localBranchNames,
                        remoteBranches: remoteBranchNames,
                        onCreateBranch: onCreateBranchTapped,
                        currentBranch: head.name
                    )
                    .padding()
                    .frame(maxHeight: .infinity)
                }
                .sheet(isPresented: $showCheckoutBranchSheet) {
                    BranchOperationView(
                        localBranches: localBranchNames,
                        remoteBranches: remoteBranchNames,
                        onCheckoutOrDelete: onCheckoutOrDelete,
                        onMergeOrRebase: { _, _, _ in },
                        currentBranch: head.name,
                        operation: .checkout
                    )
                    .padding()
                    .frame(maxHeight: .infinity)
                }
                .sheet(isPresented: $showDeleteBranchSheet) {
                    BranchOperationView(
                        localBranches: localBranchNames,
                        remoteBranches: remoteBranchNames,
                        onCheckoutOrDelete: onCheckoutOrDelete,
                        onMergeOrRebase: { _, _, _ in },
                        currentBranch: head.name,
                        operation: .delete
                    )
                    .padding()
                    .frame(maxHeight: .infinity)
                }
                .sheet(isPresented: $showCreateTagSheet) {
                    AddTagView(
                        remotes: remotes.map(\.name!),
                        onCreateTag: onCreateTagTapped
                    )
                    .padding()
                    .frame(maxHeight: .infinity)
                }
            Spacer()
            RepositoryNavigationView(isCollapsed: $isCollapsed, deleteRepositoryTapped: onDeleteRepositoryTapped)
                .font(.accessoryButton)
        }
    }
}
