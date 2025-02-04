//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct CommitsView: View {
    @State var viewModel: CommitsViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FinalCommitsView(viewModel: viewModel, width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.67)
                WIPCommitsView(viewModel: viewModel, width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.33)
                Spacer()
            }
        }
    }
}

