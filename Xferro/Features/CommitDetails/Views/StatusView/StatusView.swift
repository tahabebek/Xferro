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
        Group {
            if viewModel.selectableStatus != nil {
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
                            currentFile: $viewModel.currentFile,
                            trackedFiles: Binding<[OldNewFile]>(
                                get: { viewModel.trackedFiles.values.elements },
                                set: { _ in }
                            ),
                            untrackedFiles: Binding<[OldNewFile]>(
                                get: { viewModel.untrackedFiles.values.elements },
                                set: { _ in }
                            ),
                            hasChanges: viewModel.hasChanges,
                            onTapExclude: { file in

                            }, onTapExcludeAll: {

                            }, onTapInclude: { file in

                            }, onTapIncludeAll: {

                            }, onTapTrack: { file in
                                Task {
                                    await viewModel.trackTapped(flag: true, file: file)
                                }
                            }, onTapTrackAll: {
                                Task {
                                    await viewModel.trackAllTapped()
                                }
                            }, onTapIgnore: { file in
                                Task {
                                    await viewModel.ignoreTapped(file: file)
                                }
                            }, onTapDiscard: { file in
                                Task {
                                    await viewModel.discardTapped(file: file)
                                }
                            }
                        )
                    }
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
                        onTapDiscard: { file in
                            Task {
                                await viewModel.discardTapped(file: file)
                            }
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
                .animation(.default, value: viewModel.selectableStatus)
                .animation(.default, value: viewModel.commitSummary)
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal, 6)
    }
}

extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        viewModel.commitSummary.isEmptyOrWhitespace
    }
}
