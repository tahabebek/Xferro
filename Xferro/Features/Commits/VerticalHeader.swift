//
//  VerticalHeader.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//


import SwiftUI

struct VerticalHeader: View {

    let title: String

    var titleView: some View {
        HStack {
            Spacer()
            Text("\(title)")
                .font(.title)
            Spacer()
        }
        .frame(height: 36)
    }

    var body: some View {
        titleView
            .background(Color.red.opacity(0.3))
    }
}
