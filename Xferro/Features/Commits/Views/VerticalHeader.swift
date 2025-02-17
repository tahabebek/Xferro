//
//  VerticalHeader.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//


import SwiftUI

struct VerticalHeader<Content>: View where Content: View {
    let title: String
    let buttonsView: () -> Content

    init(title: String, @ViewBuilder buttonsView: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.buttonsView = buttonsView
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text("\(title)")
                    .font(.title2)
                Spacer(minLength: 16)
                buttonsView()
            }
            HStack {
                Spacer()
                buttonsView()
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

