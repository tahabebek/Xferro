//
//  StatusUnstagedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusUnstagedView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    let unstagedDeltaInfos: [DeltaInfo]
    let onTapInclude: ([DeltaInfo]) -> Void
    let onTapIncludeAll: () -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        Section {
            Group {
                ForEach(unstagedDeltaInfos) { deltaInfo in
                    HStack {
                        StatusRowView(currentDeltaInfo: $currentDeltaInfo, deltaInfo: deltaInfo)
                        XFerroButton(
                            title: "Include",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapInclude([deltaInfo])
                            }
                        )
                        XFerroButton(
                            title: "Discard",
                            dangerous: true,
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapDiscard(deltaInfo)
                            }
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("Excluded Changes")
                Spacer()
                XFerroButton(
                    title: "Include All",
                    onTap: {
                        onTapIncludeAll()
                    }
                )
            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: unstagedDeltaInfos)
    }
}
