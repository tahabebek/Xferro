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
                SelectableItemDetailView(commitsViewModel: commitsViewModel, detailsViewModel: commitsViewModel.detailsViewModel)
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
