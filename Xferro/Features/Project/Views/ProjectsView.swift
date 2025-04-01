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

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if viewModel.commitsViewModel.currentRepositoryInfos.count > 0 {
                    ProjectView(statusViewModel: statusViewModel, commitsViewModel: viewModel.commitsViewModel)
                } else {
                    ZStack {
                        Color(hexValue: 0x15151A)
                            .cornerRadius(8)
                        AddRepositoryButton(
                            onTapNewRepository: {
                                AppDelegate.newRepository()
                            },
                            onTapAddLocalRepository: {
                                AppDelegate.addLocalRepository()
                            },
                            onTapCloneRepository: {
                                AppDelegate.showCloneRepositoryView()
                            })
                            .padding()
                    }
                    .padding()
                }
                Spacer()
            }
            Spacer()
        }
    }
}
