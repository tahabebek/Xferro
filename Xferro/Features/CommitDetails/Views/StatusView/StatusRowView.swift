//
//  StatusRowView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusRowView: View {
    @Binding var currentDeltaInfo: DeltaInfo?
    let deltaInfo: DeltaInfo

    var isCurrent: Bool {
        if let currentDeltaInfoId = currentDeltaInfo?.id {
            currentDeltaInfoId == deltaInfo.id
        } else {
            false
        }
    }

    var body: some View {
        HStack {
            Image(systemName: deltaInfo.statusImageName).foregroundColor(deltaInfo.statusColor)
            Text(deltaInfo.statusFileName)
                .font(.body)
                .foregroundStyle(isCurrent ? Color.accentColor : Color.fabulaFore1)
            Spacer()
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 48)
        .onTapGesture {
            currentDeltaInfo = deltaInfo
        }
    }
}
