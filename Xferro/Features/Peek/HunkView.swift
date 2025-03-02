//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI/////

struct HunkView: View {
    let hunk: DiffHunk
    let fileExtension: String?
    
    init(hunk: DiffHunk, fileExtension: String? = nil) {
        self.hunk = hunk
        self.fileExtension = fileExtension
    }

    @ViewBuilder var actions: some View {
        switch hunk.type {
        case .staged:
            if hunk.selectedLinesCount > 0 {
                HStack {
                    AnyView.buttonWith(
                        title: hunk.selectedLinesCount == 1 ? "Discard Line" : "Discard Lines",
                        disabled: false,
                        dangerous: true,
                        isProminent: false,
                        isSmall: true
                    ) {

                    }
                    AnyView.buttonWith(
                        title: hunk.selectedLinesCount == 1 ? "Exclude Line" : "Exclude Lines",
                        disabled: false,
                        dangerous: false,
                        isProminent: false,
                        isSmall: true
                    ) {

                    }
                }
            } else {
                AnyView.buttonWith(
                    title: "Discard Chunk",
                    disabled: false,
                    dangerous: true,
                    isProminent: false,
                    isSmall: true
                ) {
                    hunk.discard()
                }
                HStack {
                    AnyView.buttonWith(
                        title: "Exclude Chunk",
                        disabled: false,
                        dangerous: false,
                        isProminent: false,
                        isSmall: true
                    ) {
                    }
                }
            }
        case .unstaged, .untracked:
            if hunk.selectedLinesCount > 0 {
                HStack {
                    AnyView.buttonWith(
                        title: hunk.selectedLinesCount == 1 ? "Discard Line" : "Discard Lines",
                        disabled: false,
                        dangerous: true,
                        isProminent: false,
                        isSmall: true
                    ) {

                    }
                    AnyView.buttonWith(
                        title: hunk.selectedLinesCount == 1 ? "Include Line" : "Include Lines",
                        disabled: false,
                        dangerous: false,
                        isProminent: false,
                        isSmall: true)
                    {

                    }
                }
            } else {
                HStack {
                    AnyView.buttonWith(
                        title: "Discard Chunk",
                        disabled: false,
                        dangerous: true,
                        isProminent: false,
                        isSmall: true
                    ) {
                        hunk.discard()
                    }
                    AnyView.buttonWith(
                        title: "Include Chunk",
                        disabled: false,
                        dangerous: false,
                        isProminent: false,
                        isSmall: true
                    ) {

                    }
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
                PartView(part: part, fileExtension: fileExtension)
            }
        }
        .padding(.bottom)
    }
}
