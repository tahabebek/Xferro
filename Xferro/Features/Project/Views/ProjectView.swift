//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import AppKit
import SwiftUI

struct ProjectView: View {
    @Bindable var statusViewModel: StatusViewModel
    @Bindable var commitsViewModel: CommitsViewModel
    @Bindable var wipCommitViewModel = WipCommitViewModel()

    init(commitsViewModel: CommitsViewModel, statusViewModel: StatusViewModel) {
        self.commitsViewModel = commitsViewModel
        self.statusViewModel = statusViewModel
    }

    var body: some View {
        HSplitView {
            CommitsView(
                commitsViewModel: commitsViewModel,
                onPullTapped: { type in
                    statusViewModel.pullTapped(pullType: type)
                },
                onFetchTapped: { type in
                    statusViewModel.fetchTapped(fetchType: type)
                },
                onPushTapped: { branchName, remote, type in
                    statusViewModel.pushTapped(branchName: branchName, remote:remote, pushType: type)
                },
                onAddRemoteTapped: {
                    statusViewModel.addRemoteTapped()
                },
                onGetLastSelectedRemoteIndex: {
                    statusViewModel.getLastSelectedRemoteIndex(buttonTitle: $0)
                },
                onSetLastSelectedRemote: { value, buttonTitle in
                    statusViewModel.setLastSelectedRemote(value, buttonTitle: buttonTitle)
                }
            )
            .frame(minWidth: 0)
            .frame(maxWidth: Dimensions.commitsViewMaxWidth)
            .layoutPriority(1)
            Group {
                switch commitsViewModel.currentSelectedItem?.type {
                case .regular(let type):
                    switch type {
                    case .status, .commit, .detachedCommit, .detachedTag:
                        StatusView(
                            viewModel: statusViewModel,
                            remotes: commitsViewModel.currentRepositoryInfo?.remotes ?? [],
                            stashes: commitsViewModel.currentRepositoryInfo?.stashes ?? []
                        )
                    default:
                        EmptyView()
                    }
                case .wip:
                    WipCommitView(viewModel: wipCommitViewModel)
                default:
                    EmptyView()
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
