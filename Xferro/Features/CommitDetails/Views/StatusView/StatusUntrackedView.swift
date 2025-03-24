//
//  StatusUntrackedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusUntrackedView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var files: [OldNewFile]

    let onTapTrack: (OldNewFile) -> Void
    let onTapTrackAll: () -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

    var body: some View {
        Section {
            Group {
                ForEach($files) { file in
                    HStack {
                        StatusUntrackedRowView(
                            currentFile: $currentFile,
                            file: file,
                            onTapTrack: { onTapTrack(file.wrappedValue) },
                            onTapIgnore: { onTapIgnore(file.wrappedValue) },
                            onTapDiscard: { onTapDiscard(file.wrappedValue) }
                        )
                        XFButton<Void>(
                            title: "Track",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapTrack(file.wrappedValue)
                            }
                        )
                        XFButton<Void>(
                            title: "Ignore",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapIgnore(file.wrappedValue)
                            }
                        )
                        XFButton<Void>(
                            title: "Discard",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapDiscard(file.wrappedValue)
                            }
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("\(files.count) untracked \(files.count == 1 ? "item" : "items")")
                    .font(.paragraph4)
                Spacer()
                XFButton<Void>(
                    title: "Track All",
                    onTap: {
                        onTapTrackAll()
                    }
                )
            }
            .padding(.vertical, 4)
        }
        .animation(.default, value: files.count)
    }
}
