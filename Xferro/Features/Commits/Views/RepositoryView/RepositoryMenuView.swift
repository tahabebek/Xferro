//
//  RepositoryViewMenu.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryMenuView: View {
    @Binding var isCollapsed: Bool
    let gitDir: URL
    let deleteRepositoryTapped: () -> Void

    var body: some View {
        HStack {
            Label(gitDir.deletingLastPathComponent().lastPathComponent, systemImage: "folder")
            .fixedSize()
            Spacer()
            RepositoryActionsView()
            Spacer()
            RepositoryNavigationView(isCollapsed: $isCollapsed, deleteRepositoryTapped: deleteRepositoryTapped)
        }
    }
}
