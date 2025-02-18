//
//  CirclesWithArrows.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct CirclesWithArrows<CircleContent>: View where CircleContent: View {
    let numberOfCircles: Int
    let circleContent: (Int) -> CircleContent
    let circleSize: CGFloat
    let spacing: CGFloat
    let verticalOffset: CGFloat

    private var arrowY: CGFloat { circleSize / 2  + verticalOffset }
    private var arrowHeadSize: CGFloat { circleSize / 20 }
    private let lineWidth: CGFloat = 1

    init(
        numberOfCircles: Int,
        circleSize: CGFloat = 36,
        spacing: CGFloat = 12,
        verticalOffset: CGFloat = 0,
        @ViewBuilder circleContent: @escaping (Int) -> CircleContent
    ) {
        self.numberOfCircles = numberOfCircles
        self.circleSize = circleSize
        self.spacing = circleSize + spacing
        self.circleContent = circleContent
        self.verticalOffset = verticalOffset
    }

    var body: some View {
        HStack {
            ZStack {
                ForEach(0..<(numberOfCircles-1), id: \.self) { index in
                    Path { path in
                        let startX = CGFloat(index) * spacing + circleSize
                        let endX = CGFloat(index + 1) * spacing

                        path.move(to: CGPoint(x: startX, y: arrowY))
                        path.addLine(to: CGPoint(x: endX, y: arrowY))
                    }
                    .stroke(.gray, lineWidth: lineWidth)

                    Path { path in
                        let arrowX = CGFloat(index + 1) * spacing

                        path.move(to: CGPoint(x: arrowX, y: arrowY))
                        path.addLine(to: CGPoint(x: arrowX - arrowHeadSize, y: arrowY - arrowHeadSize))
                        path.addLine(to: CGPoint(x: arrowX - arrowHeadSize, y: arrowY + arrowHeadSize))
                        path.closeSubpath()
                    }
                    .fill(Color.gray)
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

                HStack(spacing: spacing - circleSize) {
                    ForEach(0..<numberOfCircles, id: \.self) { index in
                        circleContent(index)
                            .frame(width: circleSize, height: circleSize)
                    }
                }
            }
        }
    }
}
