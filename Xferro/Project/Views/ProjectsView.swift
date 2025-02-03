//
//  ProjectsView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct ProjectsView: View {
    @State var viewModel: ProjectsViewModel
    @State var folderPickerViewModel = FolderPickerViewModel()

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let branchListViewModel = viewModel.branchListViewModel {
                    ProjectView(branchListViewModel: branchListViewModel)
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
