//
//  ProjectsView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct ProjectsView: View {
    let viewModel: ProjectsViewModel
    let folderPickerViewModel = FolderPickerViewModel()

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let commitsViewModel = viewModel.commitsViewModel {
                    ProjectView(commitsViewModel: commitsViewModel)
                } else {
                    FolderPickerView(viewModel: folderPickerViewModel)
                        .onChange(of: folderPickerViewModel.selectedFolderURL) { oldValue, newValue in
                            if let newValue {
                                viewModel.userDidSelectFolder(newValue)
                            }
                        }
                }
                Spacer()
            }
            Spacer()
        }
    }
}
