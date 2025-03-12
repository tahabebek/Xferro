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

    let onTapInclude: (OldNewFile) -> Void
    let onTapExclude: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void
    let onTapIncludeAll: () -> Void
    let onTapExcludeAll: () -> Void

    var body: some View {
        Section {
            Group {
                ForEach($files) { file in
                    HStack {
                        StatusTrackedRowView(
                            currentFile: $currentFile,
                            file: file,
                            onTapInclude: { onTapInclude(file.wrappedValue) },
                            onTapExclude: { onTapExclude(file.wrappedValue) },
                            onTapDiscard: { onTapDiscard(file.wrappedValue) }
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("\(files.count) changed \(files.count == 1 ? "file" : "files")")
                Spacer()
                if files.allSatisfy({ $0.checkState == CheckboxState.checked }) {
                    XFerroButton(
                        title: "Unselect All",
                        onTap: {
                            onTapExcludeAll()
                        }
                    )
                } else if files.allSatisfy({ $0.checkState == CheckboxState.unchecked }) {
                    XFerroButton(
                        title: "Select All",
                        onTap: {
                            onTapIncludeAll()
                        }
                    )
                } else {
                    XFerroButton(
                        title: "Select All",
                        onTap: {
                            onTapIncludeAll()
                        }
                    )
                    XFerroButton(
                        title: "Unselect All",
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
