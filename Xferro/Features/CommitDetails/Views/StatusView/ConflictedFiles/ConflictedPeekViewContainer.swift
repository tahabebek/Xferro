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
        ConflictedPeekView(file: file, text: text)
            .padding(.leading, 8)
    }
}

