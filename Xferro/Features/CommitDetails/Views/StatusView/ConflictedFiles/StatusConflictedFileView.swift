//
//  StatusConflictedFileView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/26/25.
//

import SwiftUI

struct StatusConflictedFileView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var files: [OldNewFile]
    let conflictType: ConflictType

    var body: some View {
        Section {
            Group {
                ForEach($files) { file in
                    HStack {
                        StatusConflictedRowView(currentFile: $currentFile, file: file)
                    }
                }
            }
        } header: {
            HStack {
                Text("\(files.count) conflicted \(files.count == 1 ? "file" : "files"). Fix conflicts and then continue, or abort the \(conflictType).")
                    .font(.paragraph4)
                Spacer()
            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: files.count)
    }
}
