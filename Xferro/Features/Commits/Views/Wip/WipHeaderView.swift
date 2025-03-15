//
//  WipHeaderView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct WipHeaderView: View {
    @Binding var autoCommitEnabled: Bool
    let onAddManualWipCommitTapped: () -> Void
    let onDeleteWipWorktreeTapped: () -> Void
    let tooltipForDeletion: String
    let isNotEmpty: Bool

    var body: some View {
        VerticalHeader(title: "Work in progress") {
            if !autoCommitEnabled {
                Image(systemName: "plus")
                    .contentShape(Rectangle())
                    .hoverableButton("Create wip commit") {
                        onAddManualWipCommitTapped()
                    }
            }

            if isNotEmpty {
                Image(systemName: "trash")
                    .contentShape(Rectangle())
                    .hoverableButton(tooltipForDeletion) {
                        onDeleteWipWorktreeTapped()
                    }
            }
        }
        .animation(.default, value: autoCommitEnabled)
    }
}
