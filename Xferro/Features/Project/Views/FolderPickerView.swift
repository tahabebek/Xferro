//
//  FolderPickerView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import SwiftUI

struct FolderPickerView: View {
    @State private var showFolderSelector = false
    @State var viewModel: FolderPickerViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Select a repository.")
                .font(.title2)
            Button {
                showFolderSelector = true
            } label: {
                Image(systemName: "folder.badge.plus")
                    .padding()
            }
            .fileImporter(isPresented: $showFolderSelector, allowedContentTypes: [.directory], allowsMultipleSelection: false) { result in
                guard let directory = try? result.get().first else { return }
                viewModel.usedDidSelectFolder(directory)
            }
        }
    }
}
