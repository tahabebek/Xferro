//
//  WipCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WipCommitsView: View {
    let wipCommits: WipCommitsViewModel?
    let currentSelectedItem: SelectedItem?
    let onUserTapped: (any SelectableItem) -> Void
    let isSelectedItem: (any SelectableItem) -> Bool
    let onAddManualWipCommitTapped: (SelectedItem) -> Void
    let onDeleteWipWorktreeTapped: (Repository) -> Void
    let onDeleteAllWipCommitsTapped: (SelectedItem) -> Void

    let columns = [GridItem(.adaptive(minimum: 16, maximum: 16))]

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            header
                .frame(height: 36)
                .padding(.top, 8)
        } content: {
            Group {
                VStack(spacing: 8) {
                    if let wipCommits, wipCommits.isNotEmpty {
                        HStack {
                            Text(wipCommits.item.selectableItem.wipDescription)
                                .lineLimit(2)
                            Spacer()
                        }
                        LazyVGrid(columns: columns) {
                            ForEach(wipCommits.commits) { selectableWipCommit in
                                wipRectangle(item: selectableWipCommit)
                            }
                        }
                        .animation(.snappy, value: wipCommits.commits)
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
                    onUserTapped(item)
                }
            if isSelectedItem(item) {
                SelectedItemOverlay(width: 16, height: 16, cornerRadius: 1)
            }
        }
    }

    var header: some View {
        Group {
            if let wipCommits {
                VerticalHeader(title: "Work in progress") {
                    Toggle("Auto", isOn: Binding<Bool>(
                        get: { wipCommits.autoCommitEnabled },
                        set: { wipCommits.autoCommitEnabled = $0 }
                    ))
                    .fixedSize()
                    if !wipCommits.autoCommitEnabled {
                        Image(systemName: "plus")
                            .contentShape(Rectangle())
                            .hoverableButton("Create wip commit") {
                                onAddManualWipCommitTapped(wipCommits.item)
                            }
                    }

                    if let currentSelectedItem {
                        if case .regular = currentSelectedItem.type {
                            if wipCommits.isNotEmpty {
                                Image(systemName: "eraser")
                                    .contentShape(Rectangle())
                                    .hoverableButton("Delete all the wip commits for the commit '\(wipCommits.item.oid.debugOID.prefix(4))'") {
                                        onDeleteAllWipCommitsTapped(currentSelectedItem)
                                    }
                            }

                            Image(systemName: "trash")
                                .contentShape(Rectangle())
                                .hoverableButton("Delete all the wip commits in '\(currentSelectedItem.repository.nameOfRepo)' repository") {
                                    onDeleteWipWorktreeTapped(wipCommits.item.selectableItem.repository)
                                }
                        }
                    }
                }
                .animation(.default, value: wipCommits.autoCommitEnabled)
            } else {
                EmptyView()
            }
        }
    }
}
