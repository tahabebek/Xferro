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

    init(commitsViewModel: CommitsViewModel) {
        self.commitsViewModel = commitsViewModel
    }

    var body: some View {
        HStack(spacing: 0) {
            CommitsView(commitsViewModel: commitsViewModel)
                .frame(maxWidth: Dimensions.commitsViewMaxWidth)
            StatusView(viewModel: statusViewModel)
            .frame(maxWidth: .infinity)
            .onChange(of: commitsViewModel.currentSelectedItem) {
                if let item = commitsViewModel.currentSelectedItem, case .regular(let selectableStatus) = item.type {
                    if case .status(let status) = selectableStatus {
                        if let repo = commitsViewModel.currentRepositoryInfo?.repository,
                           let head = commitsViewModel.currentRepositoryInfo?.head {
                            Task {
                                await statusViewModel.updateStatus(
                                    newSelectableStatus: status,
                                    repository: repo,
                                    head: head
                                )
                            }
                        }
                    }
                }
            }
            .onChange(of: commitsViewModel.currentRepositoryInfo) {
                if let item = commitsViewModel.currentSelectedItem, case .regular(let selectableStatus) = item.type {
                    if case .status(let status) = selectableStatus {
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
                    }
                }
            }
        }
    }
}
