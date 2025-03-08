//
//  StatusViewChangeView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusViewChangeView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    @Binding var trackedDeltaInfos: [DeltaInfo]
    @Binding var untrackedDeltaInfos: [DeltaInfo]
    let hasChanges: Bool

    let onTapExclude: (DeltaInfo) -> Void
    let onTapExcludeAll: () -> Void
    let onTapInclude: (DeltaInfo) -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (DeltaInfo) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void
    
    var body: some View {
        ZStack {
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: false) {
                if !hasChanges {
                    Text("No changes.")
                }
                LazyVStack(spacing: 4) {
                    if trackedDeltaInfos.isNotEmpty {
                        StatusTrackedView(
                            currentDeltaInfo: $currentDeltaInfo,
                            deltaInfos: $trackedDeltaInfos,
                            onTapInclude: onTapInclude,
                            onTapExclude: onTapExclude,
                            onTapDiscard: onTapDiscard,
                            onTapIncludeAll: onTapIncludeAll,
                            onTapExcludeAll: onTapExcludeAll
                        )
                    }
                    if untrackedDeltaInfos.isNotEmpty {
                        StatusUntrackedView(
                            currentDeltaInfo: $currentDeltaInfo,
                            untrackedDeltaInfos: $untrackedDeltaInfos,
                            onTapTrack: onTapTrack,
                            onTapTrackAll: onTapTrackAll,
                            onTapIgnore: onTapIgnore,
                            onTapDiscard: onTapDiscard
                        )
                    }
                }
            }
            .padding()
        }
    }
}
