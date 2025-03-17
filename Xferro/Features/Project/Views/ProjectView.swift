//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import AppKit
import SwiftUI

struct ProjectView: View {
    @Bindable var commitsViewModel: CommitsViewModel
    @Bindable var statusViewModel = StatusViewModel()
    @Bindable var wipCommitViewModel = WipCommitViewModel()

    init(commitsViewModel: CommitsViewModel) {
        self.commitsViewModel = commitsViewModel
    }

    var body: some View {
        HSplitView {
            CommitsView(commitsViewModel: commitsViewModel)
                .frame(maxWidth: Dimensions.commitsViewMaxWidth)
            Group {
                switch commitsViewModel.currentSelectedItem?.type {
                case .regular(let type):
                    switch type {
                    case .status, .commit, .detachedCommit, .detachedTag:
                        StatusView(viewModel: statusViewModel)
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
                    if let repo = commitsViewModel.currentRepositoryInfo?.repository ,
                       let head = commitsViewModel.currentRepositoryInfo?.head {
                        Task {
                            await statusViewModel.updateStatus(
                                newSelectableStatus: status,
                                repository: repo,
                                head: head
                            )
                        }
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
                if let repo = commitsViewModel.currentRepositoryInfo?.repository ,
                   let head = commitsViewModel.currentRepositoryInfo?.head {
                    Task {
                        await wipCommitViewModel.updateStatus(
                            newSelectableWipCommit: wip.selectableItem as! SelectableWipCommit,
                            repository: repo,
                            head: head
                        )
                    }
                }
            }
        }
    }
}
