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
//                    .layoutPriority(Dimensions.commitsViewPriority)
                    .frame(width: Dimensions.commitsViewIdealWidth)
                SelectableItemDetailView()
                    .layoutPriority(Dimensions.commitDetailsPriority)
                    .frame(width: Dimensions.commitDetailsViewIdealWidth)
                    .environment(commitsViewModel.detailsViewModel)
                PeekView()
//                    .layoutPriority(Dimensions.fileDetailsViewPriority)
//                    .frame(idealWidth: .infinity)
                    .environment(commitsViewModel.peekViewModel)
            }
        }
    }
}
