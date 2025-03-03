//
//  WipRectangle.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct WipRectangle: View {
    let onUserTapped: () -> Void
    let text: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.7))
                .frame(width: 16, height: 16)
                .overlay(
                    Text(text)
                        .foregroundColor(.white)
                        .font(.system(size: 8))
                )
                .onTapGesture {
                    onUserTapped()
                }
            if isSelected {
                SelectedItemOverlay(width: 16, height: 16, cornerRadius: 1)
            }
        }
    }
}
