//
//  PeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct PeekViewContainer: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    @Binding var trackedDeltaInfos: [DeltaInfo]
    @Binding var untrackedDeltaInfos: [DeltaInfo]

    let head: Head
    let onTapTrack: (DeltaInfo) -> Void
    let onTapIgnore: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach($trackedDeltaInfos) { deltaInfo in
                        PeekView(deltaInfo: deltaInfo)
                    }
                    ForEach($untrackedDeltaInfos) { deltaInfo in
                        UntrackedPeekView(
                            deltaInfo: deltaInfo,
                            onTapTrack: onTapTrack,
                            onTapIgnore: onTapIgnore,
                            onTapDiscard: onTapDiscard
                        )
                    }
                }
            }
            .onChange(of: currentDeltaInfo) { _, deltaInfo in
                if let id = deltaInfo?.id {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
            .padding(.leading, 12)
        }
        .onChange(of: trackedDeltaInfos) { oldValue, newValue in
            for deltaInfo in trackedDeltaInfos {
                Task.detached {
                    await deltaInfo.setDiffInfo(head: head)
                }
            }
        }
        .task {
            for deltaInfo in trackedDeltaInfos {
                Task.detached {
                    await deltaInfo.setDiffInfo(head: head)
                }
            }
        }
    }
}
