//
//  PartView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI
import RegexBuilder

struct PartView: View {
    @Binding var part: DiffHunkPart
    @State var isHovered: Bool = false
    let onDiscardPart: () -> Void
    let onDiscardLine: (DiffLine) -> Void

    var body: some View {
        ForEach(part.lines) { line in
            LineView(
                line: line,
                part: part,
                isFirst: line.indexInPart == 0,
                onTogglePart: {
                    part.toggle()
                }, onToggleLine: {
                    part.toggleLine(line: line)
                }, onDiscardPart: {
                    onDiscardPart()
                }, onDiscardLine: {
                    onDiscardLine(line)
                }, onHoverPart: {
                    isHovered = $0
                }
            )
            .environment(\.partIsHovered, isHovered)
            .padding(.horizontal, 4)
        }
    }
}
