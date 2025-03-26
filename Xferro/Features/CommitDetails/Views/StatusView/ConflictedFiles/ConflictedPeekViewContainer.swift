//
//  ConflictedPeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/26/25.
//

import SwiftUI

struct ConflictedPeekViewContainer: View {
    @Binding var timeStamp: Date
    @State var intitalDiffLoadIsComplete: Bool = false

    let file: OldNewFile
    let text: String

    var body: some View {
        Group {
            if file.isUntracked {
                ConflictedPeekView(
                    file: file,
                    text: text
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

