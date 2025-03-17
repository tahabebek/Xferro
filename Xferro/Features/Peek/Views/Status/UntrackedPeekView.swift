//
//  UntrackedPeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct UntrackedPeekView: View {
    let file: OldNewFile

    let onTapTrack: (OldNewFile) -> Void
    let onTapIgnore: (OldNewFile) -> Void
    let onTapDiscard: (OldNewFile) -> Void

    var body: some View {
        Group {
            VStack(spacing: 0) {
                PeekViewHeader(statusFileName: file.statusFileName, countString: "")
                    .background(Color.clear)
                    .padding(.horizontal, 8)
                Divider()
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(file.statusFileName) is untracked.")
                            .font(.title)
                        Spacer()
                    }
                    HStack {
                        XFerroButton(
                            title: "Track",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapTrack(file)
                            }
                        )
                        .padding()
                        XFerroButton(
                            title: "Ignore",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapIgnore(file)
                            }
                        )
                        .padding()
                        XFerroButton(
                            title: "Discard",
                            dangerous: true,
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapDiscard(file)
                            }
                        )
                        .padding()
                    }
                    Spacer()
                }
                .padding()
                .padding(.top)
            }
            .background(Color.clear)

        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.3),
            radius: 5,
            x: 0,
            y: 3
        )
    }
}
