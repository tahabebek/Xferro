//
//  StatusTrackedView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct StatusTrackedView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    @Binding var deltaInfos: [DeltaInfo]

    let onTapInclude: (DeltaInfo) -> Void
    let onTapExclude: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void
    let onTapIncludeAll: () -> Void
    let onTapExcludeAll: () -> Void

    var body: some View {
        Section {
            Group {
                ForEach($deltaInfos) { deltaInfo in
                    HStack {
                        StatusTrackedRowView(
                            currentDeltaInfo: $currentDeltaInfo,
                            deltaInfo: deltaInfo,
                            onTapInclude: onTapInclude,
                            onTapExclude: onTapExclude,
                            onTapDiscard: onTapDiscard
                        )
                    }
                }
            }
        } header: {
            HStack {
                Text("\(deltaInfos.count) changed \(deltaInfos.count == 1 ? "file" : "files")")
                Spacer()
                if deltaInfos.allSatisfy({ $0.checkState == CheckboxState.checked }) {
                    XFerroButton(
                        title: "Exclude All",
                        onTap: {
                            onTapExcludeAll()
                        }
                    )
                } else if deltaInfos.allSatisfy({ $0.checkState == CheckboxState.unchecked }) {
                    XFerroButton(
                        title: "Include All",
                        onTap: {
                            onTapIncludeAll()
                        }
                    )
                } else {
                    XFerroButton(
                        title: "Include All",
                        onTap: {
                            onTapIncludeAll()
                        }
                    )
                    XFerroButton(
                        title: "Exclude All",
                        onTap: {
                            onTapExcludeAll()
                        }
                    )
                }

            }
            .padding(.bottom, 4)
        }
        .animation(.default, value: deltaInfos)
    }
}
