//
//  WipCommitView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct WipCommitView: View {
    @Bindable var viewModel: WipCommitViewModel
    var body: some View {
        Group {
            if viewModel.selectableWipCommit != nil {
                HStack(spacing: 0) {
                    WipCommitFilesViewContainer(
                        currentFile: $viewModel.currentFile,
                        files: Binding<[OldNewFile]>(
                            get: { viewModel.files },
                            set: { _ in }
                        ),
                        commit: viewModel.selectableWipCommit!,
                        onBoxActionTapped: { action in
                            try? await viewModel.actionTapped(action)
                        }
                    )
                    .frame(width: Dimensions.commitDetailsViewMaxWidth)
                    if let file = viewModel.currentFile {
                        WipCommitsPeekViewContainer(file: file)
                        .id(file.id)
                    } else {
                        Spacer()
                    }
                }
                .opacity(viewModel.selectableWipCommit == nil ? 0 : 1)
            }
        }
        .padding(.horizontal, 6)
    }
}
