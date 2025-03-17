//
//  WipCommitsFileView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitsFileView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var files: [OldNewFile]

    var body: some View {
        Section {
            Group {
                ForEach($files) { file in
                    HStack {
                        WipCommitFileRowView(
                            currentFile: $currentFile,
                            file: file
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("\(files.count) changed \(files.count == 1 ? "file" : "files")")
                Spacer()
            }
            .padding(.bottom, 4)
        }
    }
}
