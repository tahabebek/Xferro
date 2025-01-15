//
//  ProjectView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import SwiftUI

struct ProjectView: View {
    @State var projectViewModel: ProjectViewModel
    @State var recentered: Bool = true
    @State var currentOffset: CGPoint = .zero
    @State var zoomScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            MenuView()
                .frame(height: 40)
            GeometryReader { geometry in
                HSplitView {
                    TreeWrapperView(
                        recentered: $recentered,
                        currentOffset: $currentOffset,
                        zoomScale: $zoomScale,
                        onHandleStateChange: handleStateChange,
                        onFocusOnCommit: focusOnCommit
                    ) {
                        AnyView(
                            EmptyView()
                        )
                    }
                    FileNavigatorView()
                    PeekView()
                }
                .environment(\.windowInfo, geometry.size)
            }
        }
        .environment(projectViewModel)
    }

    func handleStateChange() {
        if recentered {
//            if let peekCommitHash = viewModel.peekCommitHash {
//                focusOnCommit(peekCommitHash)
//            } else {
//                focusOnCommit(viewModel.currentCommitHash)
//            }
        }
    }

    func focusOnCommit(_ commit: AnyCommit) {
//        selectedCommitHash = nil
//        FocusOnCommit.focusOnCommit(
//            commitHash,
//            viewModel: viewModel,
//            windowInfo: windowInfo,
//            zoomScale: zoomScale,
//            currentOffset: $currentOffset
//        )
    }
}

struct FileNavigatorView: View {
    @Environment(ProjectViewModel.self) var projectViewModel
    var body: some View {
        Color.yellow.ignoresSafeArea()
    }
}

struct PeekView: View {
    @Environment(ProjectViewModel.self) var projectViewModel
    var body: some View {
        Color.blue.ignoresSafeArea()
    }
}
