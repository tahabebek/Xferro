//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    @Binding var hunk: DiffHunk
    let onDiscardPart: (DiffHunkPart) -> Void
    let onDiscardLine: (DiffLine) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack(alignment: .center) {
                    Text(hunk.hunkHeader.replacingOccurrences(of: "\n", with: " "))
                        .foregroundColor(Color(hexValue: 0xADBD42))
                    Spacer()
                    XFerroButton(
                        title: "Discard Hunk",
                        dangerous: true,
                        isProminent: false,
                        onTap: {
                            hunk.discard()
                        }
                    )
                }
                .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            Divider()
            PartsView(
                parts: $hunk.parts,
                onDiscardPart: onDiscardPart,
                onDiscardLine: onDiscardLine
            )
            Divider()
        }
        .padding(.bottom)
    }
}
