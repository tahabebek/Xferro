//
//  CenterLineModifier.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import SwiftUI

struct CenterLineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let size = geometry.frame(in: .local)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: size.height / 2))
                        path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                    }
                    .stroke(.blue, lineWidth: 1.0)
                    .opacity(0.5)
                    Path { path in
                        path.move(to: CGPoint(x: size.width / 2.0, y: 0))
                        path.addLine(to: CGPoint(x: size.width / 2.0, y: size.height))
                    }
                    .stroke(.blue, lineWidth: 1.0)
                    .opacity(0.5)
                }
            }
    }
}

extension View {
    func centerLines() -> some View {
        modifier(CenterLineModifier() )
    }
}
