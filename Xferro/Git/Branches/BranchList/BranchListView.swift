//
//  BranchListView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct BranchListView: View {
    @State var viewModel: BranchListViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                CommitsView(viewModel: viewModel, width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.67)
                AutoCommitsView(viewModel: viewModel, width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.33)
                Spacer()
            }
        }
    }
}

