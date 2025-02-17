//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import AppKit
import SwiftUI

struct ProjectView: View {
    @Environment(CommitsViewModel.self) var commitsViewModel
    @State var recentered: Bool = true
    @State var currentOffset: CGPoint = .zero
    @State var zoomScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                CommitsView()
                    .layoutPriority(Dimensions.commitsViewPriority)
                    .frame(minWidth: 0)
                    .frame(maxWidth: Dimensions.commitsViewIdealWidth)
                SelectableItemDetailView()
                    .layoutPriority(Dimensions.commitDetailsPriority)
                    .frame(minWidth: 0)
                    .frame(maxWidth: Dimensions.commitDetailsViewIdealWidth)
                    .environment(commitsViewModel.detailsViewModel)
                PeekView()
                    .frame(maxWidth: .infinity)
                    .layoutPriority(Dimensions.fileDetailsViewPriority)
            }
        }
    }
}

struct PeekView: View {
    //    @Environment(ProjectViewModel.self) var projectViewModel
    var body: some View {
        Color.clear.ignoresSafeArea()
    }
}
