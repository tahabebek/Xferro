//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    static let actionBoxBottomPadding: CGFloat = 4
    private static let actionBoxVerticalInnerPadding: CGFloat = 16
    private static var totalVerticalPadding: CGFloat {
        Self.actionBoxBottomPadding * 2 + Self.actionBoxVerticalInnerPadding * 2
    }

    @Bindable var viewModel: StatusViewModel

    var body: some View {
//        let _ = Self._printChanges()
        HStack(spacing: 0) {
            VStack {
                StatusActionView(
                    commitSummary: $viewModel.commitSummary,
                    commitSummaryIsEmptyOrWhitespace: commitSummaryIsEmptyOrWhitespace,
                    canCommit: viewModel.canCommit,
                    hasChanges: viewModel.hasChanges,
                    onCommitTapped: {
                        Task {
                            await viewModel.commitTapped()
                        }
                    },
                    onBoxActionTapped: { action in
                        await viewModel.actionTapped(action)
                    }
                )
                .padding()
                .background(Color(hexValue: 0x15151A))
                .cornerRadius(8)
                StatusViewChangeView(
                    currentDeltaInfo: $viewModel.currentDeltaInfo,
                    trackedDeltaInfos: $viewModel.trackedDeltaInfos,
                    untrackedDeltaInfos: $viewModel.untrackedDeltaInfos,
                    hasChanges: viewModel.hasChanges,
                    onTapExclude: { deltaInfo in
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: false, deltaInfos: [deltaInfo])
                        }
                    }, onTapExcludeAll: {
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: false)
                        }
                    }, onTapInclude: { deltaInfo in
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: true, deltaInfos: [deltaInfo])
                        }
                    }, onTapIncludeAll: {
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: true)
                        }
                    }, onTapTrack: { deltaInfo in
                        Task {
                            await viewModel.trackTapped(stage: true, deltaInfos: [deltaInfo])
                        }
                    }, onTapTrackAll: {
                        Task {
                            await viewModel.trackAllTapped()
                        }
                    }, onTapIgnore: { deltaInfo in
                        Task {
                            await viewModel.ignoreTapped(deltaInfo: deltaInfo)
                        }
                    }, onTapDiscard: { deltaInfo in
                        Task {
                            await viewModel.discardTapped(deltaInfo: deltaInfo)
                        }
                    }
                )
            }
            .frame(width: Dimensions.commitDetailsViewMaxWidth)
            PeekViewContainer(
                currentDeltaInfo: $viewModel.currentDeltaInfo,
                trackedDeltaInfos: $viewModel.trackedDeltaInfos,
                untrackedDeltaInfos: $viewModel.untrackedDeltaInfos,
                head: viewModel.head,
                onTapTrack: { deltaInfo in
                    Task {
                        await viewModel.trackTapped(stage: true, deltaInfos: [deltaInfo])
                    }
                },
                onTapIgnore: { deltaInfo in
                    Task {
                        await viewModel.ignoreTapped(deltaInfo: deltaInfo)
                    }
                },
                onTapDiscard: { deltaInfo in
                    Task {
                        await viewModel.discardTapped(deltaInfo: deltaInfo)
                    }
                }
            )
        }
        .task {
            viewModel.setInitialSelection()
        }
        .onChange(of: viewModel.selectableStatus) { oldValue, newValue in
            if oldValue.oid != newValue.oid {
                viewModel.setInitialSelection()
            }
        }
        .animation(.default, value: viewModel.selectableStatus)
        .animation(.default, value: viewModel.commitSummary)
        .padding(.horizontal, 6)
    }
}

extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        viewModel.commitSummary.isEmptyOrWhitespace
    }
}
