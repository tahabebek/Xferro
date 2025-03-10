//
//  StatusRowTextModifier.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

struct StatusRowTextModifier: ViewModifier {
    @Binding var isCurrent: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isCurrent ? Color.accentColor : Color.fabulaFore1)
            .font(.title3)
            .monospaced()
    }
}

extension View {
    func statusRowText(isCurrent: Binding<Bool>) -> some View {
        modifier(StatusRowTextModifier(isCurrent: isCurrent))
    }
}
