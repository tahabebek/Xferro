//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        Group {
            if viewModel.selectableStatus != nil {
                HStack(spacing: 0) {
                    StatusFilesViewContainer(
                        currentFile: $viewModel.currentFile,
                        trackedFiles: Binding<[OldNewFile]>(
                            get: { viewModel.trackedFiles },
                            set: { _ in }
                        ),
                        untrackedFiles: Binding<[OldNewFile]>(
                            get: { viewModel.untrackedFiles },
                            set: { _ in }
                        ),
                        commitSummary: $viewModel.commitSummary,
                        canCommit: $viewModel.canCommit,
                        hasChanges: Binding<Bool>(
                            get: { !viewModel.untrackedFiles.isEmpty || !viewModel.trackedFiles.isEmpty },
                            set: { _ in }
                        ),
                        onCommitTapped: {
                            do {
                                try await viewModel.commitTapped()
                            } catch {
                                fatalError(.unhandledError(error.localizedDescription))
                            }
                        },
                        onBoxActionTapped: { action in
                            try? await viewModel.actionTapped(action)
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
                        onTapUntrack: { file in
                            Task {
                                await viewModel.trackTapped(flag: false, file: file)
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
                        onTapDiscard: { file in
                            Task {
                                await viewModel.discardTapped(file: file)
                            }
                        }
                    )
                    .frame(width: Dimensions.commitDetailsViewMaxWidth)
                    if let file = viewModel.currentFile {
                        PeekViewContainer(
                            timeStamp: Binding<Date>(
                                get: { viewModel.selectableStatus!.timestamp },
                                set: {_ in }
                            ),
                            file: file,
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
                        .id(file.id)
                    } else {
                        Spacer()
                    }
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
                .opacity(viewModel.selectableStatus == nil ? 0 : 1)
            }
        }
        .padding(.horizontal, 6)
    }
}
