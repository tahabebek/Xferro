//
//  PeekViewHeader.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct PeekViewHeader: View {
    let statusFileName: String
    let countString: String

    var body: some View {
        HStack(spacing: 0) {
            VerticalHeader<AnyView>(title: statusFileName, horizontalPadding: 0.0)
                .frame(height: 36)
            Spacer()
            Text(countString)
                .font(.small)
        }
    }
}
