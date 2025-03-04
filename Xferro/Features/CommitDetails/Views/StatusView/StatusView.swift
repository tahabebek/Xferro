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
                    stagedDeltaInfosIsEmpty: viewModel.stagedDeltaInfos.isEmpty,
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
                    stagedDeltaInfos: viewModel.stagedDeltaInfos,
                    unstagedDeltaInfos: viewModel.unstagedDeltaInfos,
                    untrackedDeltaInfos: viewModel.untrackedDeltaInfos,
                    hasChanges: viewModel.hasChanges,
                    onTapExclude: { deltaInfos in
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: false, deltaInfos: deltaInfos)
                        }
                    }, onTapExcludeAll: {
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: false)
                        }
                    }, onTapInclude: { deltaInfos in
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: true, deltaInfos: deltaInfos)
                        }
                    }, onTapIncludeAll: {
                        Task {
                            await viewModel.stageOrUnstageTapped(stage: true)
                        }
                    }, onTapTrack: { deltaInfos in
                        Task {
                            await viewModel.trackTapped(stage: true, deltaInfos: deltaInfos)
                        }
                    }, onTapTrackAll: {
                        Task {
                            await viewModel.trackAllTapped()
                        }
                    }, onTapIgnore: { deltaInfos in
                        Task {
                            await viewModel.ignoreTapped(deltaInfo: deltaInfos)
                        }
                    }, onTapDiscard: {
                        discardDeltaInfo = $0
                    }
                )
            }
            .frame(width: Dimensions.commitDetailsViewMaxWidth)
            PeekViewContainer(viewModel: viewModel, scrollToFile: $viewModel.scrollToFile)
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
