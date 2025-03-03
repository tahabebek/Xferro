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
        HStack(spacing: 0) {
            CommitsView(commitsViewModel: commitsViewModel)
                .frame(maxWidth: Dimensions.commitsViewMaxWidth)
            SelectableItemDetailView(
                selectedItem: commitsViewModel.currentSelectedItem,
                repository: commitsViewModel.currentRepositoryInfo?.repository,
                head: commitsViewModel.currentRepositoryInfo?.head
            )
                .frame(maxWidth: .infinity)
        }
    }
}
