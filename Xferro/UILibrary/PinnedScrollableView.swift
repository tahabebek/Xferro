//
//  PinnedScrollableView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct PinnedScrollableView<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        ScrollView {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section(header: VerticalHeader(title: title)) {
                    content()
                }
            }
        }
    }
}

#Preview {
    PinnedScrollableView(title:"Section") {
        ForEach(51...100, id: \.self) { number in
            Text("Row \(number)")
        }
    }
}
