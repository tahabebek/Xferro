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
    @Binding var hasChanges: Bool

    let onTapExcludeAll: () -> Void
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
                Text("No changes.")
                    .opacity(hasChanges ? 0 : 1)
                    .frame(height: hasChanges ? 0 : 48)
                LazyVStack(spacing: 4) {
                    if trackedFiles.isNotEmpty {
                        StatusTrackedView(
                            currentFile: $currentFile,
                            files: $trackedFiles,
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
            .animation(.default, value: hasChanges)
            .padding()
        }
    }
}
