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
        VerticalHeader(title: viewModel.autoCommitEnabled ? "AutoWip Commits" :"Wip Commits") {
            Toggle("Auto", isOn: Binding<Bool>(
                get: { viewModel.autoCommitEnabled },
                set: { viewModel.autoCommitEnabled = $0 }
            ))
            .fixedSize()
            if !viewModel.autoCommitEnabled, let item = viewModel.currentSelectedItem {
                Image(systemName: "plus")
                    .contentShape(Rectangle())
                    .hoverableButton("Create wip commit") {
                        viewModel.addManualWipCommitTapped(for: item)
                    }
            }

            if let currentSelectedItem = viewModel.currentSelectedItem {
                if case .regular = currentSelectedItem.selectedItemType {
                    if viewModel.currentWipCommits != nil {
                        Image(systemName: "eraser")
                            .contentShape(Rectangle())
                            .hoverableButton("Delete all the wip commits for the commit '\(currentSelectedItem.selectableItem.oid.debugOID.prefix(4))'") {
                                viewModel.deleteAllWipCommitsTapped(for: currentSelectedItem)
                            }
                    }

                    Image(systemName: "trash")
                        .contentShape(Rectangle())
                        .hoverableButton("Delete all the wip commits in '\(currentSelectedItem.repository.nameOfRepo)' repository") {
                            viewModel.deleteWipWorktreeTapped(for: currentSelectedItem.repository)
                        }
                }
            }
        }
        .animation(.default, value: viewModel.autoCommitEnabled)
    }
}
