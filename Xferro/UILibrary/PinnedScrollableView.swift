//
//  PinnedScrollableView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct PinnedScrollableView<Header, Content>: View where Header: View, Content: View {
    let showsIndicators: Bool
    let header: () -> Header
    let content: () -> Content

    init(
        showsIndicators: Bool,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.header = header
        self.content = content
    }
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVStack {
                Section(header: header()) {
                    content()
                }
            }
        }
    }
}
