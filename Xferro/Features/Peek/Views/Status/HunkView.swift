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
                        .font(.paragraph5)
                    Spacer()
                    XFButton<Void>(
                        title: "Discard Hunk Below",
                        onTap: {
                            hunk.discard()
                        }
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            Divider()
            ZStack {
                PartsView(
                    parts: $hunk.parts,
                    onDiscardPart: onDiscardPart,
                    onDiscardLine: onDiscardLine
                )
                .zIndex(0)
                .offset(y: -1)
                PreciseLineHeightText(
                    text: hunk.parts.flatMap(\.lines).map(\.text).joined(separator: "\n")
                )
                .padding(.leading, PartView.selectBoxWidth * 2 + PartView.numberBoxWidth * 2 + 16)
                .padding(.trailing, 8)
                .frame(height: CGFloat(hunk.parts.flatMap(\.lines).count) * .diffViewLineHeight)
                .zIndex(1)
            }
        }
        .padding(.bottom)
    }
}
