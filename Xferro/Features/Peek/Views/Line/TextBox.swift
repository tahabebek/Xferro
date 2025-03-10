//
//  TextBox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct TextBox: View {
    @Environment(\.partIsHovered) var partIsHovered
    @Binding var isLineSelected: Bool
    @Binding var isAdditionOrDeletion: Bool
    @Binding var hoveredLine: Int?

    let color: Color
    let text: String
    let lineNumber: Int
    let indexInPart: Int
    let onToggleLine: () -> Void
    let onDiscardLine: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            color.opacity(LineView.backgroundOpacity)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            Text(text)
                .font(.body.monospaced())
                .frame(height: 20)
                .padding(.leading, 8)
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
            backgroundForTextBox()
        }
        .contextMenu {
            if isAdditionOrDeletion {
                Button("Discard line \(lineNumber.formatted())") {
                    onDiscardLine()
                }
            }
        }
    }

    func backgroundForTextBox() -> some View {
        if (hoveredLine != nil && hoveredLine! == indexInPart) || partIsHovered {
            color.opacity(LineView.hoveredTextBackgroundOpacity)
        } else {
            color.opacity(LineView.backgroundOpacity)
        }
    }
}
