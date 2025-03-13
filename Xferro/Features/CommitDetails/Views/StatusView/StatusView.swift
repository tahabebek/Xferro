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
    @State private var discardFile: OldNewFile? = nil
    @State private var discardAll: Bool = false

    var body: some View {
        Group {
            if viewModel.selectableStatus != nil {
                HStack(spacing: 0) {
                    StatusFilesViewContainer(
                        currentFile: $viewModel.currentFile,
                        trackedFiles: Binding<[OldNewFile]>(
                            get: { viewModel.trackedFiles.values.elements },
                            set: { _ in }
                        ),
                        untrackedFiles: Binding<[OldNewFile]>(
                            get: { viewModel.untrackedFiles.values.elements },
                            set: { _ in }
                        ),
                        commitSummary: $viewModel.commitSummary,
                        canCommit: $viewModel.canCommit,
                        hasChanges: Binding<Bool>(
                            get: { !viewModel.untrackedFiles.isEmpty || !viewModel.trackedFiles.isEmpty },
                            set: { _ in }
                        ),
                        onCommitTapped: {
                            Task {
                                try? await viewModel.commitTapped()
                            }
                        },
                        onBoxActionTapped: { action in
                            if case .discardAll = action {
                                discardAll = true
                            } else {
                                try? await viewModel.actionTapped(action)
                            }
                        },
                        onTapExcludeAll: {
                            Task {
                                await viewModel.selectAll(flag: false)
                            }
                        },
                        onTapIncludeAll: {
                            Task {
                                await viewModel.selectAll(flag: true)
                            }
                        },
                        onTapTrack: { file in
                            Task {
                                await viewModel.trackTapped(flag: true, file: file)
                            }
                        },
                        onTapTrackAll: {
                            Task {
                                await viewModel.trackAllTapped()
                            }
                        },
                        onTapIgnore: { file in
                            Task {
                                await viewModel.ignoreTapped(file: file)
                            }
                        },
                        onTapDiscard: {
                            discardFile = $0
                        }
                    )
                    .frame(width: Dimensions.commitDetailsViewMaxWidth)
                    PeekViewContainer(
                        currentFile: $viewModel.currentFile,
                        trackedFiles: Binding<[OldNewFile]>(
                            get: { viewModel.trackedFiles.values.elements },
                            set: { _ in }
                        ),
                        untrackedFiles: Binding<[OldNewFile]>(
                            get: { viewModel.untrackedFiles.values.elements },
                            set: { _ in }
                        ),
                        timeStamp: Binding<Date>(
                            get: { viewModel.selectableStatus!.timestamp },
                            set: {_ in }
                        ),
                        onTapTrack: { file in
                            Task {
                                await viewModel.trackTapped(flag: true, file: file)
                            }
                        },
                        onTapIgnore: { file in
                            Task {
                                await viewModel.ignoreTapped(file: file)
                            }
                        },
                        onTapDiscard: {
                            discardFile = $0
                        }
                    )
                }
                .task {
                    viewModel.setInitialSelection()
                }
                .onChange(of: viewModel.selectableStatus!) { oldValue, newValue in
                    if oldValue.oid != newValue.oid {
                        viewModel.setInitialSelection()
                    }
                }
                .onChange(of: discardFile) { _, newValue in
                    if let newValue, discardPopup.isPresented == false {
                        discardPopup.show(title: viewModel.discardAlertTitle(file: newValue)) {
                            discard(file: newValue)
                            self.discardFile = nil
                        } onCancel: {
                            self.discardFile = nil
                        }
                    }
                }
                .onChange(of: discardAll) { _, newValue in
                    if newValue == true, discardPopup.isPresented == false {
                        discardPopup.show(title: viewModel.discardAlertTitle(file: nil)) {
                            discardAll = false
                            Task {
                                try? await viewModel.actionTapped(.discardAll)
                            }
                        } onCancel: {
                            discardAll = false
                        }
                    }
                }
                .animation(.default, value: viewModel.selectableStatus)
                .animation(.default, value: viewModel.commitSummary)
                .opacity(viewModel.selectableStatus == nil ? 0 : 1)
            }
        }
        .padding(.horizontal, 6)
    }

    func discard(file: OldNewFile) {
        Task {
            await viewModel.discardTapped(file: file)
        }
    }
}
