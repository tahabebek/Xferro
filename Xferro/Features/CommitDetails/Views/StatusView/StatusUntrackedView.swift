//
//  StatusUntrackedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusUntrackedView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    let untrackedDeltaInfos: [DeltaInfo]

    let onTapTrack: ([DeltaInfo]) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        Section {
            Group {
                ForEach(untrackedDeltaInfos) { deltaInfo in
                    HStack {
                        StatusRowView(currentDeltaInfo: $currentDeltaInfo, deltaInfo: deltaInfo)
                        XFerroButton(
                            title: "Track",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapTrack([deltaInfo])
                            }
                        )
                        XFerroButton(
                            title: "Ignore",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapIgnore(deltaInfo)
                            }
                        )
                        XFerroButton(
                            title: "Discard",
                            dangerous: true,
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapDiscard(deltaInfo)
                            }
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("Untracked Changes")
                Spacer()
                XFerroButton(
                    title: "Track All",
                    onTap: {
                        onTapTrackAll()
                    }
                )
            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: untrackedDeltaInfos)
    }
}
