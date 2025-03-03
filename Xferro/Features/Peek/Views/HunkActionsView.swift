//
//  HunkActionsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct HunkActionsView: View {
    let hunk: DiffHunk
    
    var body: some View {
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
}
