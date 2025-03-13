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

    @State private var hoveredLine: Int?
    @State var isAdditionOrDeletion: Bool
    @State private var selectedLinesCount: Int
    @State private var isLineSelected: Bool
    @State private var isPartSelected: Bool
    private let isFirst: Bool
    private let indexInPart: Int
    private let newLine: Int
    private let oldLine: Int
    private let text: String
    private let lineType: DiffLineType
    private let numberOfLinesInPart: Int
    private let onTogglePart: () -> Void
    private let onToggleLine: () -> Void
    private let onDiscardPart: () -> Void
    private let onDiscardLine: () -> Void
    private let onHoverPart: (Bool) -> Void

    init(
        line: DiffLine,
        part: DiffHunkPart,
        isFirst: Bool,
        onTogglePart: @escaping () -> Void,
        onToggleLine: @escaping () -> Void,
        onDiscardPart: @escaping () -> Void,
        onDiscardLine: @escaping () -> Void,
        onHoverPart: @escaping (Bool) -> Void
    ) {
        self._isAdditionOrDeletion = State(initialValue: line.isAdditionOrDeletion)
        self._isPartSelected = State(initialValue: part.isSelected)
        self._selectedLinesCount = State(initialValue: part.selectedLinesCount)
        self._isLineSelected = State(initialValue: line.isSelected)
        self.numberOfLinesInPart = part.lines.count
        self.isFirst = isFirst
        self.indexInPart = line.indexInPart
        self.newLine = Int(line.newLine)
        self.oldLine = Int(line.oldLine)
        self.text = line.text
        self.lineType = line.type
        self.onToggleLine = onToggleLine
        self.onTogglePart = onTogglePart
        self.onDiscardPart = onDiscardPart
        self.onDiscardLine = onDiscardLine
        self.onHoverPart = onHoverPart
    }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                HStack {
                    HStack(spacing: 0) {
                        SelectAllBox(
                            isPartSelected: $isPartSelected,
                            selectedLinesCount: $selectedLinesCount,
                            isAdditionOrDeletion: $isAdditionOrDeletion,
                            hoveredLine: $hoveredLine,
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
                            isAdditionOrDeletion: $isAdditionOrDeletion,
                            hoveredLine: $hoveredLine,
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
                    isLineSelected: $isLineSelected,
                    isAdditionOrDeletion: $isAdditionOrDeletion,
                    hoveredLine: $hoveredLine,
                    color: color(),
                    text: text,
                    lineNumber: oldLine == -1 ? newLine : oldLine,
                    indexInPart: indexInPart,
                    onToggleLine: onToggleLine,
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
