//
//  WIPCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WIPCommitsView: View {
    @State var viewModel: CommitsViewModel
    let width: CGFloat
    var body: some View {
        PinnedScrollableView(title: "WIP Commits") {
            VStack(alignment: .leading, spacing: 0) {
                Text("Auto Commits View")
            }
            .fixedSize()
            .frame(width: width)
        }
    }
}
