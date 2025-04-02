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
    @State var selection: StatusSegmentedPicker.Section = .currentChanges

    let onTapExcludeAll: () -> Void
    let onTapIncludeAll: () -> Void
    let onTapTrack: (OldNewFile) -> Void
    let onTapUntrack: (OldNewFile) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

    var body: some View {
        ZStack {
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
            VStack {
                segmentedControl
                    .padding()
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        if trackedFiles.isNotEmpty {
                            StatusTrackedView(
                                currentFile: $currentFile,
                                files: $trackedFiles,
                                onTapDiscard: onTapDiscard,
                                onTapUntrack: onTapUntrack,
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
            }
            .padding(.bottom)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder var segmentedControl: some View {
        StatusSegmentedPicker(selection: $selection)
            .background(Color(hexValue: 0x0B0C10))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .animation(.default, value: selection)
    }
}
