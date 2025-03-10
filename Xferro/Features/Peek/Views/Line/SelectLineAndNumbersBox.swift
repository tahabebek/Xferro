//
//  SelectLineAndNumbersBox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct SelectLineAndNumbersBox: View {
    @Environment(\.partIsHovered) var partIsHovered
    @Binding var isLineSelected: Bool
    @Binding var isAdditionOrDeletion: Bool
    @Binding var hoveredLine: Int?

    let oldLineText: String
    let newLineText: String
    let color: Color
    let indexInPart: Int
    let onToggleLine: () -> Void
    let onDiscardLine: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            SelectLineBox(
                isLineSelected: $isLineSelected,
                isAdditionOrDeletion: $isAdditionOrDeletion
            )
            LineNumberBox(lineText: oldLineText)
            LineNumberBox(lineText: newLineText)
        }
        .onHover { flag in
            if flag {
                hoveredLine = indexInPart
            } else {
                hoveredLine = nil
            }
        }
        .onTapGesture {
            if isAdditionOrDeletion {
                onToggleLine()
            }
        }
        .background {
            backgroundForLineAndNumbersBox()
        }
        .contextMenu {
            if isAdditionOrDeletion {
                Button("Discard line \(oldLineText == "" ? "\(newLineText)" : "\(oldLineText)")") {
                    onDiscardLine()
                }
            }
        }
    }

    func backgroundForLineAndNumbersBox() -> some View {
        if isLineSelected {
            if (hoveredLine != nil && hoveredLine! == indexInPart) || partIsHovered {
                Color.accentColor.opacity(LineView.hoveredLineBackgroundOpacity)
            } else {
                Color.accentColor.opacity(LineView.selectedLineBackgroundOpacity)
            }
        } else {
            if (hoveredLine != nil && hoveredLine! == indexInPart) || partIsHovered {
                color.opacity(LineView.hoveredLineBackgroundOpacity)
            } else {
                color.opacity(LineView.backgroundOpacity)
            }
        }
    }
}
