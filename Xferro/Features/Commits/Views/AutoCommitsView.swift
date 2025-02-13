//
//  WIPCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WIPCommitsView: View {
    @Environment(CommitsViewModel.self) var viewModel
    let columns = [
        GridItem(.adaptive(minimum: 16, maximum: 16))
    ]
    let width: CGFloat

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            AutoCommitHeaderView()
        } content: {
            Group {
                VStack(spacing: 8) {
                    if viewModel.currentWipCommits.commits.isEmpty {
                        HStack {
                            Text("No wip commits.")
                            Spacer()
                        }
                    } else {
                        HStack {
                            Label(viewModel.currentWipCommits.title, systemImage: "w.square")
                            Spacer()
                        }
                        .frame(height: 36)
                        LazyVGrid(columns: columns) {
                            ForEach(viewModel.currentWipCommits.commits) { selectableWipCommit in
                                wipRectangle(item: selectableWipCommit)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(
                Color(hex: 0x15151A)
                    .cornerRadius(8)
            )
        }
    }

    func wipRectangle(item: SelectableWipCommit) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(
                    Text("\(item.commit.oid.debugOID.prefix(2))")
                        .foregroundColor(.white)
                        .font(.system(size: 8))
                )
                .onTapGesture {
                    viewModel.userTapped(item: item)
                }
            if viewModel.isSelected(item: item) {
                SelectedItemOverlay(width: 16, height: 16, cornerRadius: 1)
            }
        }
    }
}
