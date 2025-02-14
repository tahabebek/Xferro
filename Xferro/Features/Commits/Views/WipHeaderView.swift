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
            if !viewModel.autoCommitEnabled, let item = viewModel.currentSelectedItem {
                Image(systemName: "plus")
                    .frame(height: 36)
                    .contentShape(Rectangle())
                    .hoverButton("Create wip commit") {
                        viewModel.addManualWipCommit(for: item)
                    }
            }

            if let item = viewModel.currentSelectedItem, viewModel.currentWipCommits.commits.count > 0 {
                Image(systemName: "eraser")
                    .frame(height: 36)
                    .contentShape(Rectangle())
                    .hoverButton("Delete all the wip commits for the commit '\(item.selectableItem.oid.debugOID.prefix(4))'") {
                        viewModel.deleteAllWipCommits(of: item)
                    }
            }
            if let item = viewModel.currentSelectedItem {
                Image(systemName: "trash")
                    .frame(height: 36)
                    .contentShape(Rectangle())
                    .hoverButton("Delete all the wip commits in '\(item.repository.nameOfRepo)' repository") {
                        viewModel.deleteWipWorktree(for: item.repository)
                    }
            }
        }
        .frame(height: 36)
        .fixedSize()
        .animation(.default, value: viewModel.autoCommitEnabled)
    }
}
