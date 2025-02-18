//
//  CommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct CommitsView: View {
    var body: some View {
        VSplitView {
            NormalCommitsView()
                .padding(.trailing, 6)
            WipCommitsView()
                .padding(.trailing, 6)
        }
        .frame(width: Dimensions.commitsViewIdealWidth)
    }
}

