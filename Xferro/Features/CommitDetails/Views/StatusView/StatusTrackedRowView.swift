//
//  StatusTrackedRowView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusTrackedRowView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var file: OldNewFile
    @State var isCurrent: Bool = false

    let onTapDiscard: () -> Void
    let onTapUntrack: () -> Void

    var body: some View {
        HStack {
            TriStateCheckbox(state: $file.checkState) {
                switch file.checkState {
                case .unchecked, .partiallyChecked:
                    file.checkState = .checked
                case .checked:
                    file.checkState = .unchecked
                }
            }
            .frame(width: 16, height: 16)
            .padding(.trailing, 4)
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
        .contextMenu {
            Button(file.status == .added ? "Untrack \(file.statusFileName)" : "Discard changes in \(file.statusFileName)") {
                onTapUntrack()
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
