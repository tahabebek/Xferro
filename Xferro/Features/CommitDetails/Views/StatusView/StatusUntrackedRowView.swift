//
//  StatusUntrackedRowView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct StatusUntrackedRowView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var file: OldNewFile
    @State var isCurrent: Bool = false

    let onTapTrack: () -> Void
    let onTapIgnore: () -> Void
    let onTapDiscard: () -> Void

    var body: some View {
        HStack {
            Image(systemName: file.statusImageName).foregroundColor(file.statusColor)
            Text(file.statusFileName)
                .statusRowText(isCurrent: $isCurrent)
            Spacer()
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
        .contextMenu {
            Button("Discard \(file.statusFileName)") {
                onTapDiscard()
            }
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
