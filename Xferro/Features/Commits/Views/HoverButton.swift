//
//  HoverButton.swift
//  Xferro
//
//  Created by Taha Bebek on 2/13/25.
//

import SwiftUI

struct HoverButton: ViewModifier {
    @State private var isHovering = false
    @State private var hoverTask: Task<Void, Never>?
    let hoverText: String
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        Button {
            action?()
        } label: {
            content
        }
        .buttonStyle(.borderless)
        .onHover { flag in
            if flag {
                hoverTask = Task {
                    try? await Task.sleep(for: .seconds(2.0))
                    if !Task.isCancelled {
                        isHovering = true
                    }
                }
            } else {
                isHovering = false
                hoverTask?.cancel()
                hoverTask = nil
            }
        }
        .popover(isPresented: $isHovering, arrowEdge: .bottom) {
            Text(hoverText)
                .padding(8)
        }
    }
}

extension View {
    func hoverableButton(
        _ hoverText: String,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(HoverButton(hoverText: hoverText, action: action))
    }
}
