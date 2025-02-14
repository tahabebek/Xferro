//
//  SelectedItemOverlay.swift
//  Xferro
//
//  Created by Taha Bebek on 2/7/25.
//

import SwiftUI

struct SelectedItemOverlay: View {
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    init(
        width: CGFloat = 36,
        height: CGFloat = 36,
        color: Color = .yellow.opacity(0.6),
        lineWidth: CGFloat = 1,
        cornerRadius: CGFloat = 12
    ) {
        self.width = width
        self.height = height
        self.color = color
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(color, lineWidth: lineWidth)
            .frame(width: width - lineWidth, height: height - lineWidth)
    }
}
