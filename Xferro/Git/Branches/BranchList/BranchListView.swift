//
//  BranchListView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct BranchListView: View {
    @Environment(BranchListViewModel.self) var viewModel
    var body: some View {
        VStack {
            ForEach(viewModel.repositoryInfos) { repositoryInfo in
                Text("Branch count: \(repositoryInfo.branches.count)")
            }
        }
    }
}

#Preview(traits: .modifier(BranchListPreviewViewModel())) {
    BranchListView()
}
