//
//  StatusStagedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusStagedView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    let stagedDeltaInfos: [DeltaInfo]
    let onTapExclude: ([DeltaInfo]) -> Void
    let onTapExcludeAll: () -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        Section {
            Group {
                ForEach(stagedDeltaInfos) { deltaInfo in
                    HStack {
                        StatusRowView(
                            currentDeltaInfo: $currentDeltaInfo,
                            deltaInfo: deltaInfo
                        )
                        XFerroButton(
                            title: "Exclude",
                            isProminent: false,
                            isSmall: true,
                            onTap: {
                                onTapExclude([deltaInfo])
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
                Text("Included Changes")
                Spacer()
                XFerroButton(
                    title: "Exclude All",
                    onTap: {
                        onTapExcludeAll()
                    }
                )
            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: stagedDeltaInfos)
    }
}
