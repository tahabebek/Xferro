//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import AppKit
import OrderedCollections
import SwiftUI

struct ProjectView: View {
    @Bindable var statusViewModel: StatusViewModel
    @Bindable var commitsViewModel: CommitsViewModel
    @Bindable var wipCommitViewModel = WipCommitViewModel()

    var body: some View {
        Group {
            switch commitsViewModel.currentSelectedItem?.type {
            case .regular(let type):
                switch type {
                case .status, .commit, .detachedCommit, .detachedTag:
                    StatusView(
                        viewModel: statusViewModel,
                        remotes: commitsViewModel.currentRepositoryInfo?.remotes ?? [],
                        stashes: commitsViewModel.currentRepositoryInfo?.stashes ?? [],
                        onAddWipCommit: {
                            commitsViewModel.addWipCommit(repositoryInfo: commitsViewModel.currentRepositoryInfo!, summary: $0)
                        }
                    )
                default:
                    Color.clear
                }
            case .wip:
                WipCommitView(viewModel: wipCommitViewModel)
            default:
                Color.clear
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let repositoryInfo = commitsViewModel.currentRepositoryInfo {
                    HStack {
                        RepositoryButton(
                            repositoryInfos: Binding<[RepositoryInfo]>(
                                get: { commitsViewModel.currentRepositoryInfos.values.elements },
                                set: { _ in }
                            ),
                            currentRepositoryInfo: .constant(repositoryInfo),
                            head: repositoryInfo.head,
                            remotes: repositoryInfo.remotes,
                            localBranchNames: repositoryInfo.localBranchInfos.map(\.branch.name),
                            remoteBranchNames: repositoryInfo.remoteBranchInfos.map(\.branch.name),
                            onTapRepositoryInfo: commitsViewModel.repositoryInfoTapped,
                            onTapNewRepository: {
                                AppDelegate.newRepository()
                            },
                            onTapAddLocalRepository: {
                                AppDelegate.addLocalRepository()
                            },
                            onTapCloneRepository: {
                                AppDelegate.showCloneRepositoryView()
                            },
                            onPullTapped: { type in
                                statusViewModel.pullTapped(pullType: type)
                            },
                            onFetchTapped: { type in
                                statusViewModel.fetchTapped(fetchType: type)
                            },
                            onAddRemoteTapped: {
                                statusViewModel.addRemoteTapped()
                            },
                            onGetLastSelectedRemoteIndex: {
                                statusViewModel.getLastSelectedRemoteIndex(buttonTitle: $0)
                            },
                            onSetLastSelectedRemoteIndex: { value, buttonTitle in
                                statusViewModel.setLastSelectedRemote(value, buttonTitle: buttonTitle)
                            },
                            onCreateTagTapped: repositoryInfo.createTagTapped,
                            onCreateBranchTapped: repositoryInfo.createBranchTapped,
                            onCheckoutOrDelete: {
                                switch $2 {
                                case .checkout:
                                    repositoryInfo.checkoutBranchTapped(branchName: $0, isRemote: $1)
                                case .delete:
                                    repositoryInfo.deleteBranchTapped(branchName: $0, isRemote: $1)
                                default:
                                    fatalError(.unimplemented)
                                }
                            }
                        )
                        if let currentBranch = repositoryInfo.currentBranch {
                            BranchButton(
                                branches: Binding<[BranchInfo]>(
                                    get: { repositoryInfo.localBranchInfos },
                                    set: { _ in }
                                ),
                                remotes: repositoryInfo.remotes,
                                isCurrent: true,
                                name: currentBranch.branch.name,
                                isDetached: false,
                                branchCount: repositoryInfo.localBranchInfos.count,
                                localBranches: repositoryInfo.localBranchInfos.map(\.branch.name),
                                remoteBranches: repositoryInfo.remoteBranchInfos.map(\.branch.name),
                                currentBranch: currentBranch.branch.name,
                                onDeleteBranchTapped: repositoryInfo.onDeleteBranchTapped ?? { _ in },
                                onTapPush: statusViewModel.pushTapped,
                                onPullTapped: statusViewModel.pullTapped,
                                onGetLastSelectedRemoteIndex: statusViewModel.getLastSelectedRemoteIndex,
                                onSetLastSelectedRemoteIndex: statusViewModel.setLastSelectedRemote,
                                onAddRemoteTapped: statusViewModel.addRemoteTapped,
                                onCreateBranchTapped: repositoryInfo.createBranchTapped,
                                onCheckoutOrDelete: {
                                    switch $2 {
                                    case .checkout:
                                        repositoryInfo.checkoutBranchTapped(branchName: $0, isRemote: $1)
                                    case .delete:
                                        repositoryInfo.deleteBranchTapped(branchName: $0, isRemote: $1)
                                    default:
                                        fatalError(.invalid)
                                    }
                                    
                                },
                                onMergeOrRebase: {
                                    switch $2 {
                                    case .merge:
                                        repositoryInfo.mergeBranchTapped(target: $0, destination: $1)
                                    case .rebase:
                                        repositoryInfo.rebaseBranchTapped(target: $0, destination: $1)
                                    default:
                                        fatalError(.invalid)
                                    }
                                },
                                onTapBranch: commitsViewModel.branchInfoTapped) {
                                    
                                }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: commitsViewModel.currentRepositoryInfo) {
            refresh()
        }
        .onChange(of: commitsViewModel.currentSelectedItem) { oldValue, newValue in
            refresh()
        }
        
    }

    private func refresh() {
        if let item = commitsViewModel.currentSelectedItem{
            switch item.type {
            case .regular(let type):
                switch type {
                case .status(let status):
                    if let repositoryInfo = commitsViewModel.currentRepositoryInfo {
                        statusViewModel.updateStatus(
                            newSelectableStatus: status,
                            repositoryInfo: repositoryInfo,
                            refreshRemoteSubject: repositoryInfo.refreshRemoteSubject
                        )
                    }
                case .commit:
                    break
                case .detachedCommit:
                    break
                case .detachedTag:
                    break
                default:
                    break
                }
            case .wip(let wip):
                if let repositoryInfo = commitsViewModel.currentRepositoryInfo {
                    wipCommitViewModel.updateStatus(
                        newSelectableWipCommit: wip.selectableItem as! SelectableWipCommit,
                        repositoryInfo: repositoryInfo
                    )
                }
            }
        }
    }
}
