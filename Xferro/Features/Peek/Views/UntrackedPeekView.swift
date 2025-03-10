//
//  UntrackedPeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct UntrackedPeekView: View {
    @Binding var deltaInfo: DeltaInfo

    let onTapTrack: (DeltaInfo) -> Void
    let onTapIgnore: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        let _ = Self._printChanges()
        Group {
            VStack(spacing: 0) {
                PeekViewHeader(statusFileName: deltaInfo.statusFileName, countString: "")
                    .background(Color.clear)
                    .padding(.horizontal, 8)
                Divider()
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(deltaInfo.statusFileName) is untracked.")
                        Spacer()
                    }
                    HStack {
                        XFerroButton(
                            title: "Track",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapTrack(deltaInfo)
                            }
                        )
                        .padding()
                        XFerroButton(
                            title: "Ignore",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapIgnore(deltaInfo)
                            }
                        )
                        .padding()
                        XFerroButton(
                            title: "Discard",
                            dangerous: true,
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapDiscard(deltaInfo)
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
