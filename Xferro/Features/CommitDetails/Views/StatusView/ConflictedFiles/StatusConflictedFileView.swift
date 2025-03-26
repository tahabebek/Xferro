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
        ZStack {
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
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
                            Text("\(files.count) conflicted \(files.count == 1 ? "file" : "files"). Fix the  conflicts below and then continue, or abort the \(conflictType).")
                                .font(.paragraph4)
                            Spacer()
                        }
                        .padding(.bottom, 4)
                    }
                    .animation(.default, value: files.count)
                }
            }
        }
        .padding(.bottom)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
