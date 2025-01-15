//
//  GridViewModifier.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

struct GridViewModifier: ViewModifier {
    let gridSpacing: CGFloat
    @Environment(\.windowInfo) var windowInfo

    func body(content: Content) -> some View {
        content
            .overlay {
                TreeLayoutGridView(
                    size: CGSize(width: Dimensions.commitsViewWidth, height: windowInfo.height),
                    gridSpacing: gridSpacing
                )
            }
    }
}

extension View {
    func grid(gridSpacing: CGFloat = 40) -> some View {
        modifier(GridViewModifier(gridSpacing: gridSpacing) )
    }
}
