//
//  HoverButton.swift
//  Xferro
//
//  Created by Taha Bebek on 2/13/25.
//

import SwiftUI

struct HoverButton<Content: View>: View {
    @State private var isHovering = false
    let hoverText: String
    let action: () -> Void
    let label: () -> Content
    @State var hoverTask: Task<Void, Never>?

    var body: some View {
        Button {
            action()
        } label: {
            label()
        }
        .buttonStyle(.borderless)
        .onHover { flag in
            if flag {
                hoverTask = Task {
                    try? await Task.sleep(for: .seconds(0.25))
                    if hoverTask?.isCancelled == false {
                        isHovering = true
                    }
                }
            } else {
                isHovering = false
                hoverTask?.cancel()
            }
        }
        .popover(isPresented: $isHovering, arrowEdge: .bottom) {
            Text(hoverText)
                .padding(8)
        }
    }
}
