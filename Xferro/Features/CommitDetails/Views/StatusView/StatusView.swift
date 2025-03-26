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
                    Group {
                        if let conflictType = viewModel.conflictType {
                            StatusConflictedFilesView(
                                currentFile: $viewModel.currentFile,
                                conflictedFiles: Binding<[OldNewFile]>(
                                    get: { viewModel.conflictedFiles },
                                    set: { _ in }
                                ),
                                conflictType: conflictType,
                                onContinueMergeTapped: viewModel.continueMergeTapped,
                                onAbortMergeTapped: viewModel.abortMergeTapped,
                                onContinueRebaseTapped: viewModel.continueRebaseTapped,
                                onAbortRebaseTapped: viewModel.continueRebaseTapped
                            )
                        } else {
                            filesView
                        }
                    }
                    .frame(width: Dimensions.commitDetailsViewMaxWidth)
                    peekView
                    Spacer(minLength: 0)
                }
                .task {
                    viewModel.setInitialSelection()
                }
                .sheet(isPresented: $viewModel.shouldAddRemoteBranch) {
                    AddNewRemoteView(
                        title: viewModel.addRemoteTitle,
                        onAddRemote: viewModel.actualAddRemoteTapped
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

    @ViewBuilder var filesView: some View {
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
            onCommitTapped: viewModel.commitTapped,
            onTapExcludeAll: { viewModel.selectAllTapped(flag: false) },
            onTapIncludeAll: { viewModel.selectAllTapped(flag: true) },
            onTapTrack: { viewModel.trackTapped(flag: true, file: $0) },
            onTapUntrack: { viewModel.trackTapped(flag: false, file: $0) },
            onTapTrackAll: viewModel.trackAllTapped,
            onTapIgnore: viewModel.ignoreTapped,
            onTapDiscard: viewModel.discardTapped,
            onAmend: viewModel.amendTapped,
            onApplyStash: viewModel.applyStashTapped,
            onStash: viewModel.stashTapped,
            onDiscardAll: viewModel.discardAllTapped,
            onPopStash: viewModel.popStashTapped,
            onGetLastSelectedRemoteIndex: viewModel.getLastSelectedRemoteIndex,
            onSetLastSelectedRemoteIndex: viewModel.setLastSelectedRemote,
            onAddRemoteTapped: viewModel.addRemoteTapped,
            onAmendAndForcePushWithLease: viewModel.amendAndForcePushWithLeaseTapped,
            onAmendAndPush: viewModel.amendAndPushTapped,
            onCommitAndForcePushWithLease: viewModel.commitAndForcePushWithLeaseTapped,
            onCommitAndPush: viewModel.commitAndPushTapped,
            onTapPush: { viewModel.pushTapped(remote: $0, pushType: .normal) },
            onTapForcePushWithLease: { viewModel.forcePushWithLeaseTapped(remote: $0) }
        )
    }

    @ViewBuilder var peekView: some View {
        if let file = viewModel.currentFile {
            PeekViewContainer(
                timeStamp: Binding<Date>(
                    get: { viewModel.selectableStatus!.timestamp },
                    set: {_ in }
                ),
                file: file,
                onTapTrack: { viewModel.trackTapped(flag: true, file: $0) },
                onTapIgnore: viewModel.ignoreTapped,
                onTapDiscard: viewModel.discardTapped
            )
            .id(file.id)
        } else {
            EmptyView()
        }
    }
}
