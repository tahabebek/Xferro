//
//  WipCommitsContentView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct WipCommitsContentView: View {
    let columns = [GridItem(.adaptive(minimum: 16, maximum: 16))]
    let wipDescription: String
    let commits: [SelectableWipCommit]
    let onUserTapped: (SelectableWipCommit) -> Void
    let onIsSelected: (any SelectableItem) -> Bool

    var body: some View {
        Group {
            VStack(spacing: 8) {
                if commits.isNotEmpty {
                    HStack {
                        Text(wipDescription)
                            .lineLimit(2)
                        Spacer()
                    }
                    LazyVGrid(columns: columns) {
                        ForEach(commits) { selectableWipCommit in
                            WipRectangle(
                                onUserTapped: { onUserTapped(selectableWipCommit) },
                                text: String(selectableWipCommit.oid.debugOID.prefix(2)),
                                isSelected: onIsSelected(selectableWipCommit)
                            )
                        }
                    }
                    .animation(.snappy, value: commits)
                } else {
                    HStack {
                        Text("Empty")
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
