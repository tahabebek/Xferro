//
//  SelectedItemOverlay.swift
//  Xferro
//
//  Created by Taha Bebek on 2/7/25.
//

import SwiftUI

struct SelectedItemOverlay: View {
    @State private var rotation: Double = 0

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
        Circle()
            .strokeBorder(
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    dash: [3, 2]
                )
            )
            .foregroundStyle(color)
            .frame(width: width - lineWidth, height: height - lineWidth)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 3)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}
