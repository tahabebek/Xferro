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
            Text("\(title)")
                .font(.title2)
            Spacer()
        }
        .frame(height: 22)
    }

    var body: some View {
        titleView
    }
}
