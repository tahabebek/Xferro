//
//  PartView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI

struct PartView: View {
    let part: DiffHunkPart
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

