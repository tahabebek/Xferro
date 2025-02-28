//
//  WipCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WipCommitsView: View {
    let wipCommits: WipCommits?
    let onUserTapped: (SelectableWipCommit) -> Void
    let isSelectedItem: (SelectableWipCommit) -> Bool

    let columns = [
        GridItem(.adaptive(minimum: 16, maximum: 16))
    ]

    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            WipHeaderView()
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
                Color(hex: 0x15151A)
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
}
