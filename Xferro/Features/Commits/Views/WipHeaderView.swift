//
//  WipHeaderView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/5/25.
//

import SwiftUI

struct WipHeaderView: View {
    @Environment(CommitsViewModel.self) var viewModel

    var body: some View {
        HStack {
            VerticalHeader(title: "Wip Commits")
            Toggle("Auto", isOn: Binding<Bool>(
                get: { viewModel.autoCommitEnabled },
                set: { viewModel.autoCommitEnabled = $0 }
            ))
            if !viewModel.autoCommitEnabled {
                Button("Create wip commit") {
                    // TODO:
                }
            }
        }
        .animation(.default, value: viewModel.autoCommitEnabled)
    }
}
