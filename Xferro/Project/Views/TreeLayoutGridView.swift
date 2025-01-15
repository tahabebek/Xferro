//
//  TreeLayoutGridView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

struct TreeLayoutGridView: View {
    let size: CGSize
    let gridSpacing: CGFloat
    let opacity: Double = 0.2
    
    var numberOfVerticalLines: Int { Int(size.width / gridSpacing) }
    var numberOfHorizontalLines: Int { Int(size.height / gridSpacing) }
    
    func textForLine(_ index: Int, spacing: CGFloat) -> String {
        "\((CGFloat(index) * spacing).formatted())"
    }
    
    var body: some View {
        ZStack {
            // Add labels
            ForEach(0..<numberOfVerticalLines, id: \.self) { i in
                Text(textForLine(i, spacing: gridSpacing))
                    .font(.caption)
                    .position(x: CGFloat(i) * gridSpacing, y: 10)
                    .opacity(opacity * 2)
            }
            ForEach(0..<numberOfVerticalLines, id: \.self) { i in
                Text(textForLine(i, spacing: gridSpacing))
                    .font(.caption)
                    .position(x: CGFloat(i) * gridSpacing, y: CGFloat(numberOfHorizontalLines) * gridSpacing - 10)
                    .opacity(opacity * 2)
            }
            ForEach(0..<numberOfHorizontalLines, id: \.self) { i in
                Text(textForLine(i, spacing: gridSpacing))
                    .font(.caption)
                    .position(x: 16, y: CGFloat(i) * gridSpacing)
                    .opacity(opacity * 2)
            }
            ForEach(0..<numberOfHorizontalLines, id: \.self) { i in
                Text(textForLine(i, spacing: gridSpacing))
                    .font(.caption)
                    .position(x: CGFloat(numberOfVerticalLines) * gridSpacing - 16, y: CGFloat(i) * gridSpacing)
                    .opacity(opacity * 2)
            }
            // Draw vertical grid lines
            ForEach(0..<numberOfVerticalLines, id: \.self) { i in
                Path { path in
                    let x = CGFloat(i) * gridSpacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: CGFloat(numberOfHorizontalLines) * gridSpacing))
                }
                .stroke(Color.gray, lineWidth: 1)
                .opacity(opacity)
            }
            // Draw horizontal grid lines
            ForEach(0..<numberOfHorizontalLines, id: \.self) { i in
                Path { path in
                    let y = CGFloat(i) * gridSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: CGFloat(numberOfVerticalLines) * gridSpacing, y: y))
                }
                .stroke(Color.gray, lineWidth: 1)
                .opacity(opacity)
            }
            
            // sixe
            VStack {
                    Spacer()
                    HStack {
                        Text("\(size.width.formatted())x\(size.height.formatted())")
                            .padding()
                            .offset(x: 20, y: 10)
                        Spacer()
                    }
                }
        }
    }
}