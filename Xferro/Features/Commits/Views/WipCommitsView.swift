//
//  WipCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WipCommitsView: View {
    let viewModel: WipCommitsViewModel?
    let currentSelectedItem: SelectedItem?
    let onUserTapped: (any SelectableItem, RepositoryViewModel) -> Void
    let isSelectedItem: (any SelectableItem) -> Bool
    let onAddManualWipCommitTapped: () -> Void
    let onDeleteWipWorktreeTapped: (Repository) -> Void
    let onDeleteAllWipCommitsTapped: (SelectedItem, RepositoryViewModel) -> Void

    let columns = [GridItem(.adaptive(minimum: 16, maximum: 16))]

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            header
                .frame(height: 36)
                .padding(.top, 8)
        } content: {
            Group {
                VStack(spacing: 8) {
                    if let viewModel, viewModel.isNotEmpty {
                        HStack {
                            Text(viewModel.item.selectableItem.wipDescription)
                                .lineLimit(2)
                            Spacer()
                        }
                        LazyVGrid(columns: columns) {
                            ForEach(viewModel.commits) { selectableWipCommit in
                                wipRectangle(item: selectableWipCommit)
                            }
                        }
                        .animation(.snappy, value: viewModel.commits)
                    } else {
                        HStack {
                            Text("No history")
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(
                Color(hexValue: 0x15151A)
                    .cornerRadius(8)
            )
        }
    }

    func wipRectangle(item: SelectableWipCommit) -> some View {
        ZStack {
            Circle()
            .fill(Color.accentColor.opacity(0.7))
                .frame(width: 16, height: 16)
                .overlay(
                    Text("\(item.commit.oid.debugOID.prefix(2))")
                        .foregroundColor(.white)
                        .font(.system(size: 8))
                )
                .onTapGesture {
                    if let viewModel {
                        onUserTapped(item, viewModel.repositoryInfo)
                    }
                }
            if isSelectedItem(item) {
                SelectedItemOverlay(width: 16, height: 16, cornerRadius: 1)
            }
        }
    }

    var header: some View {
        Group {
            if let viewModel {
                VerticalHeader(title: "Work in progress") {
                    Toggle("Auto", isOn: Binding<Bool>(
                        get: { viewModel.autoCommitEnabled },
                        set: { viewModel.autoCommitEnabled = $0 }
                    ))
                    .fixedSize()
                    if !viewModel.autoCommitEnabled {
                        Image(systemName: "plus")
                            .contentShape(Rectangle())
                            .hoverableButton("Create wip commit") {
                                onAddManualWipCommitTapped()
                            }
                    }

                    if let currentSelectedItem {
                        if case .regular = currentSelectedItem.type {
                            if viewModel.isNotEmpty {
                                Image(systemName: "eraser")
                                    .contentShape(Rectangle())
                                    .hoverableButton("Delete all the wip commits for the commit '\(viewModel.item.oid.debugOID.prefix(4))'") {
                                        onDeleteAllWipCommitsTapped(currentSelectedItem, viewModel.repositoryInfo)
                                    }
                            }

                            Image(systemName: "trash")
                                .contentShape(Rectangle())
                                .hoverableButton("Delete all the wip commits in '\(viewModel.repositoryInfo.repository.nameOfRepo)' repository") {
                                    onDeleteWipWorktreeTapped(viewModel.repositoryInfo.repository)
                                }
                        }
                    }
                }
                .animation(.default, value: viewModel.autoCommitEnabled)
            } else {
                EmptyView()
            }
        }
    }
}
