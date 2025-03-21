//
//  ProjectsView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct ProjectsView: View {
    @Bindable var viewModel: ProjectsViewModel
    let statusViewModel: StatusViewModel
    let folderPickerViewModel = FolderPickerViewModel()

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let commitsViewModel = viewModel.commitsViewModel {
                    ProjectView(commitsViewModel: commitsViewModel, statusViewModel: statusViewModel)
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
