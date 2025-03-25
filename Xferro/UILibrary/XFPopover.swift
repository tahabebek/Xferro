//
//  XFPopover.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import SwiftUI

struct XFPopover<T: View>: ViewModifier {
    @Binding var isPresented: Bool
    let contentView: () -> T

    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented) {
                contentView()
            }
    }
}

extension View {
    func xfPopover<T: View>(
        isPresented: Binding<Bool>,
        contentView: @escaping () -> T
    ) -> some View {
        self.modifier(XFPopover(isPresented: isPresented, contentView: contentView))
    }
}

