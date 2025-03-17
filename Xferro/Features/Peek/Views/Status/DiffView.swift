//
//  DiffView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/13/25.
//

import SwiftUI

struct DiffView: View {
    let file: OldNewFile

    var body: some View {
        VStack(spacing: 0) {
            Text("No difference.")
                .frame(height: file.diffInfo is NoDiffInfo ? 44 : 0)
                .opacity(file.diffInfo is NoDiffInfo ? 1 : 0)
            Text("Binary files differ.")
                .frame(height: file.diffInfo is BinaryDiffInfo ? 44 : 0)
                .opacity(file.diffInfo is BinaryDiffInfo ? 1 : 0)
            ForEach(file.diffInfo?.hunks() ?? []) { hunk in
                HunkView(
                    hunk: Binding<DiffHunk>(
                        get: { hunk },
                        set: { _ in }
                    ),
                    onDiscardPart: {
                        file.discardPart($0)
                    },
                    onDiscardLine: {
                        file.discardLine($0)
                    }
                )
            }
        }
        .opacity(file.diffInfo == nil ? 0 : 1)
    }
}
