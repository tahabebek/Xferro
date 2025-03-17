//
//  WipCommitFileRowView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitFileRowView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var file: OldNewFile
    @State var isCurrent: Bool = false

    var body: some View {
        HStack {
            Text(file.statusFileName)
                .statusRowText(isCurrent: $isCurrent)
            Spacer()
            Image(systemName: file.statusImageName).foregroundColor(file.statusColor)
                .frame(width: 24, height: 24)
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 48)
        .onTapGesture {
            currentFile = file
        }
        .onAppear {
            updateIsCurrent()
        }
        .onChange(of: currentFile?.id) {
            updateIsCurrent()
        }
    }

    private func updateIsCurrent() {
        if let currentFileId = currentFile?.id, currentFileId == file.id {
            isCurrent = true
        } else {
            isCurrent = false
        }
    }
}
