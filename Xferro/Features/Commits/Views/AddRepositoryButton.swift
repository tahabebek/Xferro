//
//  AddRepositoryButton.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct AddRepositoryButton: View {
    let viewModel: CommitsViewModel
    @State private var showFolderSelector: Bool = false
    var body: some View {
        Image(systemName: "plus")
            .frame(height: 36) .contentShape(Rectangle())
            .hoverableButton("Add a repostory") {
                showFolderSelector = true
            }
            .fileImporter(isPresented: $showFolderSelector, allowedContentTypes: [.directory], allowsMultipleSelection: false) { result in
                guard let directory = try? result.get().first else { return }
                viewModel.usedDidSelectFolder(directory)
            }
    }
}
