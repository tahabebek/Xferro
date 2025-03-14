//
//  LineView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.//
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
    let showText: Bool
    let color: Color

    init(
        hoveredLine: Int? = nil,
        selectedLinesCount: Binding<Int>,
        isPartSelected: Binding<Bool>,
        isLineSelected: Binding<Bool>,
        isAdditionOrDeletion: Bool,
        isFirst: Bool,
        indexInPart: Int,
        newLine: Int,
        oldLine: Int,
        text: String,
        lineType: DiffLineType,
        numberOfLinesInPart: Int,
        onTogglePart: @escaping () -> Void,
        onToggleLine: @escaping () -> Void,
        onDiscardPart: @escaping () -> Void,
        onDiscardLine: @escaping () -> Void,
        onHoverPart: @escaping (Bool) -> Void,
        showText: Bool = true
    ) {
        self.hoveredLine = hoveredLine
        self._selectedLinesCount = selectedLinesCount
        self._isPartSelected = isPartSelected
        self._isLineSelected = isLineSelected
        self.isAdditionOrDeletion = isAdditionOrDeletion
        self.isFirst = isFirst
        self.indexInPart = indexInPart
        self.newLine = newLine
        self.oldLine = oldLine
        self.text = text
        self.lineType = lineType
        self.numberOfLinesInPart = numberOfLinesInPart
        self.onTogglePart = onTogglePart
        self.onToggleLine = onToggleLine
        self.onDiscardPart = onDiscardPart
        self.onDiscardLine = onDiscardLine
        self.onHoverPart = onHoverPart
        self.showText = showText
        self.color = switch lineType {
        case .addition:
            Color(hexValue: 0x28A745)
        case .deletion:
            Color(hexValue: 0xDC3545)
        default:
            Color.clear
        }
    }

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
                            color: color,
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
                            color: color,
                            indexInPart: indexInPart,
                            onToggleLine: onToggleLine,
                            onDiscardLine: onDiscardLine
                        )
                    }
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: PartView.selectBoxHeight)
                .minimumScaleFactor(0.75)
                    // Just show the background without text
                ZStack {
                    color.opacity(LineView.backgroundOpacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)

                    if (hoveredLine != nil && hoveredLine! == indexInPart) {
                        color.opacity(LineView.hoveredTextBackgroundOpacity)
                            .frame(maxWidth: .infinity)
                            .frame(height: 20)
                    }
                }
                Spacer()
            }
        }
        .frame(height: 20)
    }

    func lineNumber(_ line: Int) -> String {
        line == -1 ? "" : line.formatted()
    }
}
