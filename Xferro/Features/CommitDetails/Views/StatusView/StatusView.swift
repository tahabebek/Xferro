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
                        viewModel.commitTapped()
                    },
                    onBoxActionTapped: { action in
                        viewModel.actionTapped(action)
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
                    onTapExclude: {
                        viewModel.stageOrUnstageTapped(stage: false, deltaInfos: $0)
                    }, onTapExcludeAll: {
                        viewModel.stageOrUnstageTapped(stage: false)
                    }, onTapInclude: {
                        viewModel.stageOrUnstageTapped(stage: true, deltaInfos: $0)
                    }, onTapIncludeAll: {
                        viewModel.stageOrUnstageTapped(stage: true)
                    }, onTapTrack: {
                        viewModel.trackTapped(stage: true, deltaInfos: $0)
                    }, onTapTrackAll: {
                        viewModel.trackAllTapped()
                    }, onTapIgnore: {
                        viewModel.ignoreTapped(deltaInfo: $0)
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
        viewModel.discardTapped(deltaInfo: deltaInfo)
    }
}

extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        viewModel.commitSummary.isEmptyOrWhitespace
    }
}
