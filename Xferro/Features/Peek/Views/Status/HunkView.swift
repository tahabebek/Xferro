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
                    XFerroButton<Void>(
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
            ZStack {
                PartsView(
                    parts: $hunk.parts,
                    onDiscardPart: onDiscardPart,
                    onDiscardLine: onDiscardLine
                )
                .zIndex(0)
                .offset(y: 3)
                PreciseLineHeightText(
                    text: hunk.parts.flatMap(\.lines).map(\.text).joined(separator: "\n")
                )
                .padding(.leading, PartView.selectBoxWidth * 2 + PartView.numberBoxWidth * 2 + 16)
                .padding(.trailing, 8)
                .frame(height: CGFloat(hunk.parts.flatMap(\.lines).count) * 20)
                .zIndex(1)
            }
        }
        .padding(.bottom)
    }
}
