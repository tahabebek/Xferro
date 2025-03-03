//
//  BranchCommitContentView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchCommitContentView: View {
    let summary: String
    var body: some View {
        ZStack {
            Text(summary)
                .font(.caption)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
                .allowsTightening(true)
                .padding(6)
                .lineLimit(4)
                .foregroundColor(Color.fabulaFore1)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }

    }
}
