//
//  PeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct PeekViewContainer: View {
    @Binding var currentFile: OldNewFile?
    @Binding var trackedFiles: [OldNewFile]
    @Binding var untrackedFiles: [OldNewFile]
    @Binding var timeStamp: Date
    @State var intitalDiffLoadIsComplete: Bool = false

    let onTapTrack: (OldNewFile) -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach($trackedFiles) { file in
                        PeekView(file: file, timeStamp: $timeStamp)
                    }
                    ForEach($untrackedFiles) { file in
                        UntrackedPeekView(
                            file: file,
                            onTapTrack: onTapTrack,
                            onTapIgnore: onTapIgnore,
                            onTapDiscard: onTapDiscard
                        )
                    }
                }
            }
            .onChange(of: currentFile?.id) { _, id in
                withAnimation {
                    if let id {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
            .task(id: timeStamp) {
                if !intitalDiffLoadIsComplete {
                    intitalDiffLoadIsComplete = true
                    for file in trackedFiles {
                        await file.setDiffInfo()
                    }
                }
            }
            .padding(.leading, 12)
        }
    }
}
