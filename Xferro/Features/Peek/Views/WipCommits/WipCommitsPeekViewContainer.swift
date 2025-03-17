//
//  WipCommitsPeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitsPeekViewContainer: View {
    let file: OldNewFile

    var body: some View {
        PeekView(file: file)
        .padding(.leading, 8)
    }
}

