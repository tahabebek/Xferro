//
//  Octagon.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct Octagon: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let side = min(width, height)
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = side / 2

        let startAngle = CGFloat.pi / 8
        let angleIncrement = CGFloat.pi / 4 // 45° in radians

        var path = Path()

        let firstX = center.x + radius * cos(startAngle)
        let firstY = center.y + radius * sin(startAngle)
        path.move(to: CGPoint(x: firstX, y: firstY))

        for i in 1...7 {
            let angle = startAngle + angleIncrement * CGFloat(i)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close the path
        path.closeSubpath()
        return path
    }
}
