//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import AppKit
import SwiftUI

struct ProjectView: View {
    let commitsViewModel: CommitsViewModel
    @State private var recentered: Bool = true
    @State private var currentOffset: CGPoint = .zero
    @State private var zoomScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                CommitsView(commitsViewModel: commitsViewModel)
                    .frame(width: Dimensions.commitsViewMaxWidth)
                SelectableItemDetailView(selectedItem: commitsViewModel.currentSelectedItem) { repository, fileURLs in
                    commitsViewModel.discardFileButtonTapped(repository: repository, fileURLs: fileURLs)
                } commitTapped: { repository, message in
                    commitsViewModel.commitTapped(repository: repository, message: message)
                } amendTapped: { Repository, message in
                    commitsViewModel.amendTapped(repository: Repository, message: message)
                } stageAllTapped: { repository in
                    commitsViewModel.stageAllButtonTapped(repository: repository)
                } stageOrUnstageTapped: { flag, repository, deltaInfos in
                    commitsViewModel.stageOrUnstageButtonTapped(stage: flag, repository: repository, deltaInfos: deltaInfos)
                } ignoreTapped: { repository, deltaInfo in
                    commitsViewModel.ignoreButtonTapped(repository: repository, deltaInfo: deltaInfo)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
