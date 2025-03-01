//
//  PartView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI
import RegexBuilder

struct PartView: View {
    let part: DiffHunkPart
    let fileExtension: String?
    
    init(part: DiffHunkPart, fileExtension: String? = nil) {
        self.part = part
        self.fileExtension = fileExtension
    }
    
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
