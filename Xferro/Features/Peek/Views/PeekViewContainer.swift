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
        PeekView(
            timeStamp: $timeStamp,
            file: file,
            onTapTrack: onTapTrack,
            onTapIgnore: onTapIgnore,
            onTapDiscard: onTapDiscard
        )
        .padding(.leading, 8)
    }
}
