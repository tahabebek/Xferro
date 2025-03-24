//
//  SelectLineBox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct SelectLineBox: View {
    @Binding var isLineSelected: Bool
    let isAdditionOrDeletion: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(isLineSelected ? "✓" : " ")
                .font(.diff)
                .opacity(isAdditionOrDeletion ? 1 : 0)
            Spacer(minLength: 0)
            Divider()
        }
        .frame(width: PartView.selectBoxWidth)
        .contentShape(Rectangle())
    }
}
