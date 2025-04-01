//
//  RepositoryButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/31/25.
//

import SwiftUI

struct RepositoryButton: View {
    @Binding var repositoryInfos: [RepositoryInfo]
    @Binding var currentRepositoryInfo: RepositoryInfo
    @State var showOtherActions: Bool = false
    @State var showButtons = false
    @State var selectedRemoteForFetch: Remote? = nil
    @State var showCreateBranchSheet = false
    @State var showCheckoutBranchSheet = false
    @State var showCreateTagSheet = false
    @State var showDeleteBranchSheet = false
    
    let head: Head
    let remotes: [Remote]
    let localBranchNames: [String]
    let remoteBranchNames: [String]
    
    let onTapRepositoryInfo: (RepositoryInfo) -> Void
    let onTapNewRepository: () -> Void
    let onTapAddLocalRepository: () -> Void
    let onTapCloneRepository: () -> Void
    let onPullTapped: (Repository.PullType) -> Void
    let onFetchTapped: (Repository.FetchType) -> Void
    let onAddRemoteTapped: () -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onCreateTagTapped: (String, String?, String, Bool) -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void

    var body: some View {
        XFButton<RepositoryInfo, Text>(
            title: "Current Repository",
            options: Binding<[XFButtonOption<RepositoryInfo>]>(
                get: { repositoryInfos.map( {
                    XFButtonOption(title: $0.repository.nameOfRepo, data: $0)
                })},
                set: { _ in }
            ),
            selectedOptionIndex: .constant(0),
            addMoreOptionsText: "New repository",
            addMoreOptionsText2: "Add local repository",
            addMoreOptionsText3: "Clone repository",
            onTapOption: {
                onTapRepositoryInfo($0.data)
            },
            onTapAddMore: {
                onTapNewRepository()
            },
            onTapAddMore2: {
                onTapAddLocalRepository()
            },
            onTapAddMore3: {
                onTapCloneRepository()
            },
            onTap: {
                showOtherActions.toggle()
            },
            otherActionsTapped: {
                showOtherActions.toggle()
            }
        )
        .xfPopover(isPresented: $showOtherActions) {
            RepositoryMenuViewButtons(
                options: Binding<[XFButtonOption<Remote>]>(
                    get: { remotes.map( {
                        XFButtonOption(title: $0.name!, data: $0)
                    })},
                    set: { _ in }
                ),
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
    }
}
