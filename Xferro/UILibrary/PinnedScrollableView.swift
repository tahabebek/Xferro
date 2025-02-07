//
//  PinnedScrollableView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct PinnedScrollableView<Header: View, Content: View>: View {
    let showsIndicators: Bool
    let header: () -> Header
    let content: () -> Content

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
