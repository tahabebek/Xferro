//
//  SelectLineBox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct SelectLineBox: View {
    @Binding var isLineSelected: Bool
    @Binding var isAdditionOrDeletion: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Text(isLineSelected ? "✓" : " ")
                .monospaced()
                .opacity(isAdditionOrDeletion ? 1 : 0)
            Spacer(minLength: 0)
            Divider()
        }
        .frame(width: 20)
        .contentShape(Rectangle())
    }
}
