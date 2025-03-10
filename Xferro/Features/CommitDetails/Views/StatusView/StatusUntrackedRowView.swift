//
//  StatusUntrackedRowView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct StatusUntrackedRowView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    @Binding var deltaInfo: DeltaInfo
    @State var isCurrent: Bool = false

    let onTapTrack: () -> Void
    let onTapIgnore: () -> Void
    let onTapDiscard: () -> Void

    var body: some View {
        HStack {
            Image(systemName: deltaInfo.statusImageName).foregroundColor(deltaInfo.statusColor)
            Text(deltaInfo.statusFileName)
                .statusRowText(isCurrent: $isCurrent)
            Spacer()
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
        .contextMenu {
            Button("Discard \(deltaInfo.statusFileName)") {
                onTapDiscard()
            }
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
