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
                    .frame(maxWidth: Dimensions.commitsViewMaxWidth)
                    .frame(minWidth: 0)
                SelectableItemDetailView()
                    .frame(maxWidth: Dimensions.commitDetailsViewMaxWidth)
                    .frame(minWidth: 0)
                    .environment(commitsViewModel.detailsViewModel)
                PeekView()
                    .frame(idealWidth: .infinity)
                    .environment(commitsViewModel.peekViewModel)
            }
        }
    }
}
