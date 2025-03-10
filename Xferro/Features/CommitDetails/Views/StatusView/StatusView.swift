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

    @Environment(DiscardPopup.self) var discardPopup
    @Bindable var viewModel: StatusViewModel
    @State private var discardDeltaInfo: DeltaInfo? = nil

    var body: some View {
        let _ = Self._printChanges()
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
                    }, onTapDiscard: {
                        discardDeltaInfo = $0
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
                onTapDiscard: {
                    discardDeltaInfo = $0
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
        .onChange(of: discardDeltaInfo) { _, newValue in
            if let newValue, discardPopup.isPresented == false {
                discardPopup.show(title: viewModel.discardAlertTitle(deltaInfo: newValue)) {
                    discard(deltaInfo: newValue)
                    self.discardDeltaInfo = nil
                } onCancel: {
                    self.discardDeltaInfo = nil
                }
            }
        }
        .animation(.default, value: viewModel.selectableStatus)
        .animation(.default, value: viewModel.commitSummary)
        .padding(.horizontal, 6)
    }

    func discard(deltaInfo: DeltaInfo) {
        Task {
            await viewModel.discardTapped(deltaInfo: deltaInfo)
        }
    }
}

extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        viewModel.commitSummary.isEmptyOrWhitespace
    }
}
