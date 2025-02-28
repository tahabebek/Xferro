//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    let parts: [DiffHunkPart]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(parts) { part in
                PartView(part: part)
            }
        }
        .padding(.vertical)
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }
}
