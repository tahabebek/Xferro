//
//  UTTreeView.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 1/2/25.
//

import SwiftUI
import SentrySwiftUI

struct TreeWrapperView: View {
    static var lastOffSetForDocument: [String: CGPoint] = [:]
    static var lastZoomScaleForDocument: [String: CGFloat] = [:]
    static var lastIsRecenteredForDocument: [String: Bool] = [:]

    @Environment(ProjectViewModel.self) var projectViewModel
    @Binding var recentered: Bool
    @Binding var currentOffset: CGPoint
    @Binding var zoomScale: CGFloat
    @Environment(\.windowInfo) var windowInfo

    let onHandleStateChange: () -> Void
    let onFocusOnCommit: (AnyCommit) -> Void
    let peekView: () -> AnyView

    init(
        recentered: Binding<Bool>,
        currentOffset: Binding<CGPoint>,
        zoomScale: Binding<CGFloat>,
        onHandleStateChange: @escaping () -> Void,
        onFocusOnCommit: @escaping (AnyCommit) -> Void,
        peekView: @escaping () -> AnyView
    ) {
        self._recentered = recentered
        self._currentOffset = currentOffset
        self._zoomScale = zoomScale
        self.onHandleStateChange = onHandleStateChange
        self.onFocusOnCommit = onFocusOnCommit
        self.peekView = peekView
    }

    var body: some View {
        if let tree = projectViewModel.tree {
            HSplitView {
                ZStack {
                    Color.green.opacity(0.001)
                        .frame(width: Dimensions.commitsViewWidth, height: windowInfo.height)
                        .zoomAndPannable(
                            viewModel: projectViewModel,
                            currentOffset: $currentOffset,
                            zoomScale: $zoomScale,
                            isRecentered: $recentered
                        )
                        .overlay(alignment: .topTrailing) {
                            buttons
                        }
                    TreeView(
                        tree: tree,
                        horizontalSpacing: Dimensions.nodeHorizontalSpacing,
                        verticalSpacing: Dimensions.nodeVerticalSpacing,
                        onManualCommitTapped: { commit in
                            recentered = true
                            projectViewModel.manualCommitTapped(commit)
                        },
                        onAutoCommitTapped: { commit in
                            recentered = true
                            projectViewModel.autoCommitTapped(commit)
                        }
                    )
                    .layoutPriority(Dimensions.commitsViewPriority)
                    .animation(.default, value: currentOffset)
                    .animation(.default, value: projectViewModel.tree)
                    .animation(.default, value: recentered)
                    .animation(.default, value: projectViewModel.currentCommit)
                    .animation(.default, value: projectViewModel.peekCommit)
                    .frame(width: Dimensions.commitsViewWidth, height: windowInfo.height)
                    .onPreferenceChange(NodePositionsKey.self) { positions in
                        projectViewModel.setNodePositions(positions)
                    }
                    .onChange(of: projectViewModel.tree) { _, _ in
                        onHandleStateChange()
                    }
                    .onChange(of: recentered) { oldValue, newValue in
                        if !oldValue && newValue {
                            onFocusOnCommit(projectViewModel.peekCommit ?? projectViewModel.currentCommit)
                        }
                    }
                    .onChange(of: projectViewModel.currentCommit) { oldValue, newValue in
                        if oldValue != newValue {
                            onHandleStateChange()
                        }
                    }
                    .onChange(of: projectViewModel.peekCommit) { oldValue, newValue in
                        if oldValue != newValue {
                            onHandleStateChange()
                        }
                    }
                    .scaleEffect(zoomScale)
                    .offset(x: currentOffset.x, y: currentOffset.y)
                    .sentryTrace("TreeView")
                }
                peekView()
                    .layoutPriority(Dimensions.fileDetailsViewPriority)
                    .frame(minWidth: Dimensions.fileDetailsViewWidth, idealWidth: Dimensions.fileDetailsViewWidth, maxWidth: .infinity)
                    .sentryTrace("PeekView")
            }
            .id(projectViewModel.idForDocument)
            .task {
                let id = projectViewModel.idForDocument
                self.currentOffset =
                if let lastOffset = Self.lastOffSetForDocument[id] {
                    lastOffset
                } else {
                    .zero
                }
                self.zoomScale =
                if let lastScale = Self.lastZoomScaleForDocument[id] {
                    lastScale
                } else {
                    1.0
                }
                self.recentered =
                if let lastIsRecentered = Self.lastIsRecenteredForDocument[id] {
                    lastIsRecentered
                } else {
                    true
                }
            }
            .onAppear {
                onHandleStateChange()
            }
            .onDisappear {
                let idForDocument = projectViewModel.idForDocument
                Self.lastOffSetForDocument[idForDocument] = currentOffset
                Self.lastIsRecenteredForDocument[idForDocument] = recentered
                Self.lastZoomScaleForDocument[idForDocument] = zoomScale
            }
        } else {
            Text("Waiting for you to modify a file.")
                .font(.callout)
        }
    }

    @ViewBuilder var buttons : some View {
        VStack(alignment: .trailing, spacing: 8) {
            if !recentered {
                Button {
                    recentered = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.right.and.arrow.down.left.rectangle.fill")
                        Text("Re-center Tree")
                    }
                }
                .padding(.horizontal)
            }
            if let peekCommit = projectViewModel.peekCommit {
                Button {
                    projectViewModel.restoreTapped(peekCommit)
                } label: {
                    HStack {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                        Text("Restore Commit")
                    }
                }
                .padding(.horizontal)
            }

            let selectedCommit = projectViewModel.peekCommit ?? projectViewModel.currentCommit
            if !selectedCommit.isMarked {
                Button {
                    projectViewModel.mark(selectedCommit, flag: true)
                } label: {
                    HStack {
                        Image(systemName: "bookmark")
                        Text("Mark Commit")
                    }
                }
                .padding(.horizontal)
            } else {
                Button {
                    projectViewModel.mark(selectedCommit, flag: false)
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Unmark Commit")
                    }
                }
                .padding(.horizontal)
            }
        }
        .foregroundStyle(.white)
        .cornerRadius(4)
        .buttonStyle(.borderless)
        .padding(.vertical)
    }
}
