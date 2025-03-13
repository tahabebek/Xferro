//
//  LineView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI

struct LineView: View {
    static let backgroundOpacity: CGFloat = 0.2
    static let hoveredTextBackgroundOpacity: CGFloat = 0.7
    static let hoveredLineBackgroundOpacity: CGFloat = 0.7
    static let selectedLineBackgroundOpacity: CGFloat = 0.5
    static let hoveredPartBackgroundOpacity: CGFloat = 0.7
    @State private var hoveredLine: Int? = nil
    @Binding var selectedLinesCount: Int
    @Binding var isPartSelected: Bool
    @Binding var isLineSelected: Bool
    let isAdditionOrDeletion: Bool
    let isFirst: Bool
    let indexInPart: Int
    let newLine: Int
    let oldLine: Int
    let text: String
    let lineType: DiffLineType
    let numberOfLinesInPart: Int
    let onTogglePart: () -> Void
    let onToggleLine: () -> Void
    let onDiscardPart: () -> Void
    let onDiscardLine: () -> Void
    let onHoverPart: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                HStack {
                    HStack(spacing: 0) {
                        SelectAllBox(
                            isPartSelected: $isPartSelected,
                            selectedLinesCount: $selectedLinesCount,
                            hoveredLine: $hoveredLine,
                            isAdditionOrDeletion: isAdditionOrDeletion,
                            isFirst: isFirst,
                            color: color(),
                            indexInPart: indexInPart,
                            numberOfLinesInPart: numberOfLinesInPart,
                            onTogglePart: onTogglePart,
                            onDiscardPart: onDiscardPart,
                            onHoverPart: onHoverPart
                        )
                        SelectLineAndNumbersBox(
                            isLineSelected: $isLineSelected,
                            hoveredLine: $hoveredLine,
                            isAdditionOrDeletion: isAdditionOrDeletion,
                            oldLineText: lineNumber(oldLine),
                            newLineText: lineNumber(newLine),
                            color: color(),
                            indexInPart: indexInPart,
                            onToggleLine: onToggleLine,
                            onDiscardLine: onDiscardLine
                        )
                    }
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                TextBox(
                    hoveredLine: $hoveredLine,
                    isAdditionOrDeletion: isAdditionOrDeletion,
                    color: color(),
                    text: text,
                    lineNumber: oldLine == -1 ? newLine : oldLine,
                    indexInPart: indexInPart,
                    onDiscardLine: onDiscardLine
                )
                Spacer()
            }
        }
        .frame(height: 20)
    }

    func lineNumber(_ line: Int) -> String {
        line == -1 ? "" : line.formatted()
    }

    func color() -> Color {
        switch lineType {
        case .addition:
            Color(hexValue: 0x28A745)
        case .deletion:
            Color(hexValue: 0xDC3545)
        default:
            Color.clear
        }
    }
}
