//
//  WIPCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WIPCommitsView: View {
    @Environment(CommitsViewModel.self) var viewModel
    let width: CGFloat
    
    var body: some View {
        PinnedScrollableView(title: "AutoWIP Commits", showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("Auto Commits View")
                Spacer()
            }
            .fixedSize()
            .frame(width: width)
        }
    }
}
