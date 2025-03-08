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
                }
            )
            .padding(.horizontal, 4)
        }
    }
}
