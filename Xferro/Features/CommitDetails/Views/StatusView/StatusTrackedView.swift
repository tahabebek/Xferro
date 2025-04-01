//
//  StatusTrackedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct StatusTrackedView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var files: [OldNewFile]

    let onTapDiscard: (OldNewFile) -> Void
    let onTapUntrack: (OldNewFile) -> Void
    let onTapIncludeAll: () -> Void
    let onTapExcludeAll: () -> Void

    var body: some View {
        Section {
            Group {
                ForEach($files) { file in
                    StatusTrackedRowView(
                        currentFile: $currentFile,
                        file: file,
                        onTapDiscard: { onTapDiscard(file.wrappedValue) },
                        onTapUntrack: { onTapUntrack(file.wrappedValue) }
                    )
                }
            }
        } header: {
            HStack {
                Text("\(files.count) changed \(files.count == 1 ? "file" : "files")")
                    .font(.paragraph4)
                Spacer()
                if files.allSatisfy({ $0.checkState == CheckboxState.checked }) {
                    XFButton<Void,Text>(
                        title: "Unselect All",
                        isSmall: true,
                        onTap: {
                            onTapExcludeAll()
                        }
                    )
                } else if files.allSatisfy({ $0.checkState == CheckboxState.unchecked }) {
                    XFButton<Void,Text>(
                        title: "Select All",
                        isSmall: true,
                        onTap: {
                            onTapIncludeAll()
                        }
                    )
                } else {
                    XFButton<Void,Text>(
                        title: "Select All",
                        isSmall: true,
                        onTap: {
                            onTapIncludeAll()
                        }
                    )
                    XFButton<Void,Text>(
                        title: "Unselect All",
                        isSmall: true,
                        onTap: {
                            onTapExcludeAll()
                        }
                    )
                }

            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: files.count)
    }
}
