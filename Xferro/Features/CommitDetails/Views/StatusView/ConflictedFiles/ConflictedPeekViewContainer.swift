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

    var body: some View {
        ConflictedPeekView(file: file)
            .padding(.leading, 8)
            .onChange(of: timeStamp) {
                Task {
                    await file.setDiffInfoForStatus()
                }
            }
            .task {
                await file.setDiffInfoForStatus()
            }
    }
}

