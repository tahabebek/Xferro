//
//  RepositoryTagsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryTagsView: View {
    let tags: [RepositoryViewModel.TagInfo]
    let onUserTapped: (((any SelectableItem)) -> Void)?
    let onIsSelected: (((any SelectableItem)) -> Bool)?

    var body: some View {
        if let onUserTapped, let onIsSelected, tags.isNotEmpty {
            RepositoryActualTagsView(
                tags: tags,
                onUserTapped: onUserTapped,
                onIsSelected: onIsSelected
            )
        } else {
            RepositoryEmptyView()
        }
    }
}
