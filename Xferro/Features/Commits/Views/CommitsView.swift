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
            WipCommitsView()
        }
        .frame(minWidth: Dimensions.commitsViewIdealWidth)
    }
}

