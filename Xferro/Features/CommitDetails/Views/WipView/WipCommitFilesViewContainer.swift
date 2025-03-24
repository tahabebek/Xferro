//
//  WipCommitFilesViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitFilesViewContainer: View {
    @Binding var currentFile: OldNewFile?
    @Binding var files: [OldNewFile]

    let commit: SelectableWipCommit
    let onBoxActionTapped: (WipCommitActionButtonsView.BoxAction) async -> Void

    var body: some View {
        VStack {
            HStack {
                Text(commit.commit.committer.time.formatted())
                    .padding()
                Spacer()
            }
            WipCommitsActionView(onBoxActionTapped: onBoxActionTapped)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hexValue: 0x15151A))
            .cornerRadius(8)
            WipCommitsChangeView(
                currentFile: $currentFile,
                files: $files
            )
        }
    }
}
