//
//  StatusTrackedRowView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusTrackedRowView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    @Binding var deltaInfo: DeltaInfo
    @State var isCurrent: Bool = false

    let onTapInclude: (DeltaInfo) -> Void
    let onTapExclude: (DeltaInfo) -> Void
    let onTapDiscard: (DeltaInfo) -> Void

    var body: some View {
        HStack {
            TriStateCheckbox(state: $deltaInfo.checkState) {
                switch deltaInfo.checkState {
                case .unchecked, .partiallyChecked:
                    deltaInfo.checkState = .checked
                case .checked:
                    deltaInfo.checkState = .unchecked
                }
            }
            .frame(width: 16, height: 16)
            .padding(.trailing, 4)
            Text(deltaInfo.statusFileName)
                .statusRowText(isCurrent: $isCurrent)
            Spacer()
            Image(systemName: deltaInfo.statusImageName).foregroundColor(deltaInfo.statusColor)
                .frame(width: 24, height: 24)
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 48)
        .onTapGesture {
            currentDeltaInfo = deltaInfo
        }
        .onAppear {
            updateIsCurrent()
        }
        .onChange(of: currentDeltaInfo) {
            updateIsCurrent()
        }
    }

    private func updateIsCurrent() {
        if let currentDeltaInfoId = currentDeltaInfo?.id, currentDeltaInfoId == deltaInfo.id {
            isCurrent = true
        } else {
            isCurrent = false
        }
    }
}
