//
//  StatusConflictedFilesView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/26/25.
//

import SwiftUI

struct StatusConflictedFilesView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var conflictedFiles: [OldNewFile]

    let conflictType: ConflictType

    let onContinueMergeTapped: () -> Void
    let onAbortMergeTapped: () -> Void
    let onContinueRebaseTapped: () -> Void
    let onAbortRebaseTapped: () -> Void

    var body: some View {
        VStack {
            StatusConflictedActionView(
                conflictType: conflictType,
                onContinueMergeTapped: onContinueMergeTapped,
                onAbortMergeTapped: onAbortMergeTapped,
                onContinueRebaseTapped: onContinueRebaseTapped,
                onAbortRebaseTapped: onAbortRebaseTapped
            )
            .padding()
            .background(Color(hexValue: 0x15151A))
            .cornerRadius(8)
            StatusConflictedFileView(
                currentFile: $currentFile,
                files: $conflictedFiles,
                conflictType: conflictType
            )
        }

    }
}
