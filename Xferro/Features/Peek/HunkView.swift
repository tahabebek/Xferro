//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    let hunk: DiffHunk

    @ViewBuilder var actions: some View {
        switch hunk.type {
        case .staged:
            if hunk.selectedLinesCount > 0 {
                HStack {
                    XFerroButton(
                        title: hunk.selectedLinesCount == 1 ? "Discard Line" : "Discard Lines",
                        dangerous: true,
                        isProminent: false,
                        isSmall: true,
                        onTap: {
                            fatalError(.unimplemented)
                        }
                    )
                    XFerroButton(
                        title: hunk.selectedLinesCount == 1 ? "Exclude Line" : "Exclude Lines",
                        isProminent: false,
                        isSmall: true,
                        onTap: {
                            fatalError(.unimplemented)
                        }
                    )
                }
            } else {
                XFerroButton(
                    title: "Discard Chunk",
                    dangerous: true,
                    isProminent: false,
                    isSmall: true,
                    onTap: {
                        hunk.discard()
                    }
                )

                XFerroButton(
                    title: "Exclude Chunk",
                    isProminent: false,
                    isSmall: true,
                    onTap: {
                        fatalError(.unimplemented)
                    }
                )
            }
        case .unstaged, .untracked:
            if hunk.selectedLinesCount > 0 {
                HStack {
                    XFerroButton(
                        title: hunk.selectedLinesCount == 1 ? "Discard Line" : "Discard Lines",
                        dangerous: true,
                        isProminent: false,
                        isSmall: true,
                        onTap: {
                            fatalError(.unimplemented)
                        }
                    )
                    XFerroButton(
                        title: hunk.selectedLinesCount == 1 ? "Include Line" : "Include Lines",
                        isProminent: false,
                        isSmall: true,
                        onTap: {
                            fatalError(.unimplemented)
                        }
                    )
                }
            } else {
                HStack {
                    XFerroButton(
                        title: "Discard Chunk",
                        dangerous: true,
                        isProminent: false,
                        isSmall: true,
                        onTap: {
                            hunk.discard()
                        }
                    )

                    XFerroButton(
                        title: "Include Chunk",
                        isProminent: false,
                        isSmall: true,
                        onTap: {
                            fatalError(.unimplemented)
                        }
                    )
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack(alignment: .center) {
                    Text(hunk.insertionText.replacingOccurrences(of: "\n", with: " "))
                        .foregroundColor(Color(hexValue: 0xADBD42))
                    Spacer()
                    actions
                }
                .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            Divider()
            ForEach(hunk.parts) { part in
                PartView(part: part)
            }
        }
        .padding(.bottom)
    }
}
