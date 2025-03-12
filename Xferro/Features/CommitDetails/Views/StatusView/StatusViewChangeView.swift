//
//  StatusViewChangeView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusViewChangeView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var trackedFiles: [OldNewFile]
    @Binding var untrackedFiles: [OldNewFile]
    let hasChanges: Bool

    let onTapExclude: (OldNewFile) -> Void
    let onTapExcludeAll: () -> Void
    let onTapInclude: (OldNewFile) -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (OldNewFile) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void
    
    var body: some View {
        ZStack {
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: false) {
                if !hasChanges {
                    Text("No changes.")
                }
                LazyVStack(spacing: 4) {
                    if trackedFiles.isNotEmpty {
                        StatusTrackedView(
                            currentFile: $currentFile,
                            files: $trackedFiles,
                            onTapInclude: onTapInclude,
                            onTapExclude: onTapExclude,
                            onTapDiscard: onTapDiscard,
                            onTapIncludeAll: onTapIncludeAll,
                            onTapExcludeAll: onTapExcludeAll
                        )
                    }
                    if untrackedFiles.isNotEmpty {
                        StatusUntrackedView(
                            currentFile: $currentFile,
                            files: $untrackedFiles,
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
