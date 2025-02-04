//
//  PinnedScrollableView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct PinnedScrollableView<Content: View>: View {
    let title: String
    let showsIndicators: Bool
    let content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVStack {
                Section(header: VerticalHeader(title: title)) {
                    content()
                }
            }
        }
    }
}
