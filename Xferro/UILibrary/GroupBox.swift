//
//  GroupBox.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct GroupBoxView<Content: View>: View {
    let title: String
    let image: String?
    let content: () -> Content
    let padding: CGFloat = 8
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
            GroupBox(label: GroupBoxLabel(title: title, image: image)) {
                content()
                    .padding(8)
            }
//            .padding(8)
        }
    }
}

fileprivate
struct GroupBoxLabel: View {
    let title: String
    let image: String?
    var body: some View {
        HStack {
            if let image {
                Image(systemName: image)
            }
            Text(title)
        }
    }
}

#Preview {
    GroupBoxView(title: "Title", image: "archivebox") {
        Text("GroupBox Content")
            .padding()
    }
}
