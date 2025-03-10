//
//  StatusUntrackedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusUntrackedView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    @Binding var untrackedDeltaInfos: [DeltaInfo]

    let onTapTrack: (DeltaInfo) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        Section {
            Group {
                ForEach($untrackedDeltaInfos) { deltaInfo in
                    HStack {
                        StatusUntrackedRowView(
                            currentDeltaInfo: $currentDeltaInfo,
                            deltaInfo: deltaInfo,
                            onTapTrack: { onTapTrack(deltaInfo.wrappedValue) },
                            onTapIgnore: { onTapIgnore(deltaInfo.wrappedValue) },
                            onTapDiscard: { onTapDiscard(deltaInfo.wrappedValue) }
                        )
                        XFerroButton(
                            title: "Track",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapTrack(deltaInfo.wrappedValue)
                            }
                        )
                        XFerroButton(
                            title: "Ignore",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapIgnore(deltaInfo.wrappedValue)
                            }
                        )
                        XFerroButton(
                            title: "Discard",
                            dangerous: true,
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapDiscard(deltaInfo.wrappedValue)
                            }
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("\(untrackedDeltaInfos.count) untracked \(untrackedDeltaInfos.count == 1 ? "item" : "items")")
                Spacer()
                XFerroButton(
                    title: "Track All",
                    onTap: {
                        onTapTrackAll()
                    }
                )
            }
            .padding(.vertical, 4)
        }
        .animation(.default, value: untrackedDeltaInfos)
    }
}
