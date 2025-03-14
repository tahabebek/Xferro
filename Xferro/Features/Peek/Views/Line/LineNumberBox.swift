//
//  LineNumberBox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct LineNumberBox: View {
    let lineText: String

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Text(lineText)
                .padding(.trailing, 2)
            Divider()
        }
        .frame(width: PartView.numberBoxWidth)
    }
}
