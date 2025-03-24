//
//  PartView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI
import RegexBuilder

struct PartView: View {
    static let selectBoxWidth = 20.0
    static let numberBoxWidth = 40.0

    @Binding var part: DiffHunkPart
    @State var isHovered: Bool = false
    let onDiscardPart: () -> Void
    let onDiscardLine: (DiffLine) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach($part.lines) { line in
                LineView(
                    selectedLinesCount: $part.selectedLinesCount,
                    isPartSelected: $part.isSelected,
                    isLineSelected: line.isSelected,
                    isAdditionOrDeletion: line.wrappedValue.isAdditionOrDeletion,
                    isFirst: line.wrappedValue.indexInPart == 0,
                    indexInPart: line.wrappedValue.indexInPart,
                    newLine: line.wrappedValue.newLine,
                    oldLine: line.wrappedValue.oldLine,
                    text: line.wrappedValue.text,
                    lineType: line.wrappedValue.type,
                    numberOfLinesInPart: part.lines.count,
                    onTogglePart: part.toggle,
                    onToggleLine: { part.toggleLine(line.wrappedValue) },
                    onDiscardPart: onDiscardPart,
                    onDiscardLine: { onDiscardLine(line.wrappedValue) },
                    onHoverPart: { isHovered = $0 },
                    showText: false
                )
                .environment(\.partIsHovered, isHovered)
                .padding(.horizontal, 4)
            }
        }
    }
}
