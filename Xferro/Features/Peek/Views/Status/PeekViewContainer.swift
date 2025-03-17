//
//  PeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct PeekViewContainer: View {
    @Binding var timeStamp: Date
    @State var intitalDiffLoadIsComplete: Bool = false

    let file: OldNewFile
    let onTapTrack: (OldNewFile) -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

    var body: some View {
        Group {
            if file.isUntracked {
                UntrackedPeekView(
                    file: file,
                    onTapTrack: onTapTrack,
                    onTapIgnore: onTapIgnore,
                    onTapDiscard: onTapDiscard
                )
            } else {
                PeekView(file: file)
            }
        }
        .padding(.leading, 8)
        .onChange(of: timeStamp) {
            Task {
                await file.setDiffInfoForStatus()
            }
        }
        .onChange(of: file) {
            Task {
                await file.setDiffInfoForStatus()
            }
        }
        .task(id: timeStamp) {
            if !intitalDiffLoadIsComplete {
                intitalDiffLoadIsComplete = true
                await file.setDiffInfoForStatus()
            }
        }
    }
}
