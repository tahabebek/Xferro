//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

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
                    .padding(.trailing, 6)
                SelectableItemDetailView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(commitsViewModel.detailsViewModel)
                PeekView()
            }
        }
    }
}

struct PeekView: View {
    //    @Environment(ProjectViewModel.self) var projectViewModel
    var body: some View {
        Color.blue.ignoresSafeArea()
    }
}
