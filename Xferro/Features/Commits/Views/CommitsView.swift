//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct CommitsView: View {
    @Environment(CommitsViewModel.self) var viewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                NormalCommitsView(width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                Divider()
                    .padding(.bottom, 8)
                WIPCommitsView(width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.3)
                Spacer()
            }
        }
    }
}

