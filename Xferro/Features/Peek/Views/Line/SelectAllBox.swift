//
//  SelectAllBox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct SelectAllBox: View {
    @Environment(\.partIsHovered) var partIsHovered
    @Binding var isPartSelected: Bool
    @Binding var selectedLinesCount: Int
    @Binding var hoveredLine: Int?

    let isAdditionOrDeletion: Bool
    let isFirst: Bool
    let color: Color
    let indexInPart: Int
    let numberOfLinesInPart: Int
    let onTogglePart: () -> Void
    let onDiscardPart: () -> Void
    let onHoverPart: (Bool) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            let string: String = if isFirst {
                if isPartSelected {
                    "✓"
                } else if selectedLinesCount > 0 {
                    "-"
                } else {
                    " "
                }
            } else {
                " "
            }
            Text(string)
                .monospaced()
                .opacity(isAdditionOrDeletion ? 1 : 0)
            Spacer(minLength: 0)
            Divider()
        }
        .frame(width: PartView.selectBoxWidth)
        .contentShape(Rectangle())
        .contextMenu {
            if isAdditionOrDeletion {
                Button("Discard \(numberOfLinesInPart == 1 ? "line" : "lines")") {
                    onDiscardPart()
                }
            }
        }
        .onTapGesture {
            if isAdditionOrDeletion {
                onTogglePart()
            }
        }
        .background {
            backgroundForSelectAllBox()
        }
        .onHover {
            onHoverPart($0)
        }
    }

    func backgroundForSelectAllBox() -> some View {
        if isAdditionOrDeletion {
            if selectedLinesCount > 0 {
                if hoveredLine != nil || partIsHovered {
                    Color.accentColor.opacity(LineView.hoveredLineBackgroundOpacity)
                } else {
                    Color.accentColor.opacity(LineView.selectedLineBackgroundOpacity)
                }
            } else {
                if (hoveredLine != nil && hoveredLine! == indexInPart) || partIsHovered {
                    color.opacity(LineView.hoveredPartBackgroundOpacity)
                } else {
                    color.opacity(LineView.backgroundOpacity)
                }
            }
        } else {
            Color.clear
        }
    }
}
