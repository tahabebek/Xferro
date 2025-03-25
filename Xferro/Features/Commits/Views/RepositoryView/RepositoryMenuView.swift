//
//  RepositoryViewMenu.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryMenuView: View {
    @Binding var isCollapsed: Bool
    @Binding var errorString: String?
    @Binding var showError: Bool
    @State var showButtons = false
    @State var selectedRemoteForFetch: Remote?
    @State var options: [XFButtonOption<Remote>] = []
    @State var showCreateBranchSheet = false
    @State var showCheckoutBranchSheet = false
    @State var showCreateTagSheet = false
    @State var showDeleteBranchSheet = false

    let onDeleteRepositoryTapped: () -> Void
    let onPullTapped: (StatusViewModel.PullType) -> Void
    let onFetchTapped: (StatusViewModel.FetchType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemote: (Int, String) -> Void
    let onCreateTagTapped: (String, String?, String, Bool) -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onBranchOperationTapped: (String, Bool, BranchOperationView.OperationType) -> Void

    let gitDir: URL
    let head: Head
    let remotes: [Remote]
    let isSelected: Bool
    let localBranchNames: [String]
    let remoteBranchNames: [String]

    init(
        isCollapsed: Binding<Bool>,
        errorString: Binding<String?>,
        showError: Binding<Bool>,
        onDeleteRepositoryTapped: @escaping () -> Void,
        onPullTapped: @escaping (StatusViewModel.PullType) -> Void,
        onFetchTapped: @escaping  (StatusViewModel.FetchType) -> Void,
        onAddRemoteTapped: @escaping  () -> Void,
        onGetLastSelectedRemoteIndex: @escaping (String) -> Int,
        onSetLastSelectedRemote: @escaping (Int, String) -> Void,
        onCreateBranchTapped: @escaping (String, String, Bool, Bool) -> Void,
        onBranchOperationTapped: @escaping (String, Bool, BranchOperationView.OperationType) -> Void,
        onCreateTagTapped: @escaping (String, String?, String, Bool) -> Void,
        gitDir: URL,
        head: Head,
        remotes: [Remote],
        localBranches: [BranchInfo],
        remoteBranches: [BranchInfo],
        isSelected: Bool
    ) {
        self._isCollapsed = isCollapsed
        self._errorString = errorString
        self._showError = showError
        self.onDeleteRepositoryTapped = onDeleteRepositoryTapped
        self.onPullTapped = onPullTapped
        self.onFetchTapped = onFetchTapped
        self.onAddRemoteTapped = onAddRemoteTapped
        self.onGetLastSelectedRemoteIndex = onGetLastSelectedRemoteIndex
        self.onSetLastSelectedRemote = onSetLastSelectedRemote
        self.onCreateBranchTapped = onCreateBranchTapped
        self.onBranchOperationTapped = onBranchOperationTapped
        self.onCreateTagTapped = onCreateTagTapped
        self.gitDir = gitDir
        self.head = head
        self.remotes = remotes
        self.localBranchNames = localBranches.map(\.branch.name)
        self.remoteBranchNames = remoteBranches.map(\.branch.name)
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
                    RepositoryMenuViewButtons(
                        options: $options,
                        selectedRemoteForFetch: $selectedRemoteForFetch,
                        showButtons: $showButtons,
                        remotes: remotes,
                        head: head,
                        onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                        onSetLastSelectedRemote: onSetLastSelectedRemote,
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
                        onConfirm: onBranchOperationTapped,
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
                        onConfirm: onBranchOperationTapped,
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
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorString!),
                dismissButton: .default(
                    Text("OK")
                )
            )
        }
    }
}
