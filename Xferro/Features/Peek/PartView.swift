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
        ForEach(part.lines.indices, id: \.self) { index in
            LineView(line: part.lines[index], part: part, isFirst: index == 0)
                .padding(.horizontal, 4)
        }
    }
}

