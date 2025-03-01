//
//  VerticalHeader.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//


import SwiftUI

struct VerticalHeader<Content>: View where Content: View {
    let title: String
    let titleColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let buttonsView: () -> Content

    init(
        title: String,
        titleColor: Color = .white,
        horizontalPadding: CGFloat = 8.0,
        verticalPadding: CGFloat = 0.0,
        @ViewBuilder buttonsView: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.titleColor = titleColor
        self.buttonsView = buttonsView
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text("\(title)")
                    .font(.title2)
                    .foregroundColor(titleColor)
                Spacer(minLength: 0)
                buttonsView()
            }
            HStack {
                Spacer(minLength: 0)
                buttonsView()
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }
}

