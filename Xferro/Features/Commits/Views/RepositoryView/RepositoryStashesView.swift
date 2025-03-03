//
//  RepositoryStashesView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryStashesView: View {
    let stashes: [SelectableStash]
    let onUserTapped: (((any SelectableItem)) -> Void)?
    let onIsSelected: (((any SelectableItem)) -> Bool)?

    var body: some View {
        if let onUserTapped, let onIsSelected, stashes.isNotEmpty {
            RepositoryActualStashesView(
                stashes: stashes,
                onUserTapped: onUserTapped,
                onIsSelected: onIsSelected
            )
        } else {
            RepositoryEmptyView()
        }
    }
}
