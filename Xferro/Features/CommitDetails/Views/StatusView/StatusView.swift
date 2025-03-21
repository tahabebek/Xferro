//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct StatusView: View {
    @Bindable var viewModel: StatusViewModel
    let remotes: [Remote]
    let stashes: [SelectableStash]

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
                        remotes: remotes,
                        stashes: stashes,
                        onCommitTapped: {
                            do {
                                try await viewModel.commitTapped()
                            } catch {
                                fatalError(.unhandledError(error.localizedDescription))
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
                        },
                        onAmend: {
                            Task {
                                try await viewModel.amendTapped()
                            }
                        },
                        onApplyStash: { stash in
                            Task {
                                try await viewModel.onApplyStash(stash: stash)
                            }
                        },
                        onStash: {
                            Task {
                                try await viewModel.onStash()
                            }
                        },
                        onDiscardAll: {
                            Task {
                                try await viewModel.discardAllTapped()
                            }
                        },
                        onPopStash: {
                            Task {
                                try await viewModel.onPopStash()
                            }
                        },
                        onGetLastSelectedRemoteIndex: { remote in
                            return viewModel.getLastSelectedRemoteIndex(buttonTitle: remote)
                        },
                        onSetLastSelectedRemoteIndex: { index, remote in
                            viewModel.setLastSelectedRemote(index, buttonTitle: remote)
                        },
                        onAddRemoteTapped: {
                            viewModel.addRemoteTapped()
                        },
                        onAmendAndForcePushWithLease: { remote in
                            Task {
                                try await viewModel.onAmendAndForcePushWithLease(remote: remote)
                            }
                        }, onAmendAndPush: { remote in
                            Task {
                                try await viewModel.onAmendAndPush(remote: remote)
                            }
                        }, onCommitAndForcePushWithLease: { remote in
                            Task {
                                try await viewModel.onCommitAndForcePushWithLease(remote: remote)
                            }
                        }, onCommitAndPush: { remote in
                            Task {
                                try await viewModel.onCommitAndPush(remote: remote)
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
                        EmptyView()
                    }
                    Spacer(minLength: 0)
                }
                .task {
                    viewModel.setInitialSelection()
                }
                .sheet(isPresented: $viewModel.shouldAddRemoteBranch) {
                    AddNewRemoteView(
                        title: viewModel.addRemoteTitle,
                        onAddRemote: { fetchURLString, pushURLString, remoteName in
                            Task {
                                await viewModel.onAddRemote(
                                    fetchURLString: fetchURLString,
                                    pushURLString: pushURLString,
                                    remoteName: remoteName
                                )
                            }
                        }
                    )
                        .padding()
                        .frame(maxHeight: .infinity)
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
        .padding(.leading, 8)
    }
}
