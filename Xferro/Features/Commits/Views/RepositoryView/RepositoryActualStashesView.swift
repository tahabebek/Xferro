//
//  RepositoryActualStashesView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryActualStashesView: View {
    let stashes: [SelectableStash]
    let onUserTapped: ((any SelectableItem)) -> Void
    let onIsSelected: ((any SelectableItem)) -> Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(stashes) { selectableStash in
                    ZStack {
                        FlaredRounded {
                            VStack {
                                Text("\(selectableStash.stash.oid.debugOID.prefix(4))")
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            }
                        }
                        .frame(width: 80, height: 80)
                        .onTapGesture {
                            onUserTapped(selectableStash)
                        }
                        if onIsSelected(selectableStash) {
                            SelectedItemOverlay(width: 80, height: 80)
                        }
                    }
                }
            }
            .fixedSize()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .animation(.default, value: stashes)
    }
}
