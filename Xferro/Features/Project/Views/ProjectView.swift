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
                    .frame(maxWidth: Dimensions.commitsViewMaxWidth)
                    .frame(minWidth: 0)
                SelectableItemDetailView(detailsViewModel: commitsViewModel.detailsViewModel) {
                    commitsViewModel.currentDeltaInfos[$0]
                } setDeltaInfo: { oid, deltaInfo in
                    commitsViewModel.setCurrentDeltaInfo(oid: oid, deltaInfo: deltaInfo)
                } discardTapped: { repository, fileURLs in
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
                    .frame(maxWidth: Dimensions.commitDetailsViewMaxWidth)
                    .frame(minWidth: 0)
                    .environment(commitsViewModel.detailsViewModel)
                PeekView(hunks: HunkFactory.makeHunks(
                    selectableItem: commitsViewModel.currentSelectedItem?.selectableItem,
                    deltaInfo: commitsViewModel.currentDeltaInfo)
                )
                .frame(idealWidth: .infinity)
            }
        }
    }
}
