//
//  RepositoryActualTagsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryActualTagsView: View {
    let tags: [TagInfo]
    let onUserTapped: ((any SelectableItem)) -> Void
    let onIsSelected: ((any SelectableItem)) -> Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(tags) { tagInfo in
                    ZStack {
                        FlaredCircle {
                            VStack {
                                Text("\(tagInfo.tag.tag.name)")
                                    .font(.title)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(maxWidth: 70)
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                Text("\(tagInfo.tag.oid.debugOID.prefix(4))")
                                    .font(.footnote)
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            }
                        }
                        .frame(width: 80, height: 80)
                        .onTapGesture {
                            onUserTapped(tagInfo.tag)
                        }
                        if onIsSelected(tagInfo.tag) {
                            SelectedItemOverlay(width: 80, height: 80)
                        }
                    }
                }
            }
            .fixedSize()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
