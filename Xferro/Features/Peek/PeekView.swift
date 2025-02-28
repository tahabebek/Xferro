//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    let hunks: [DiffHunk]

    var body: some View {
        List {
            ForEach(hunks) { hunk in
                Section {
                    HunkView(parts: hunk.parts)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .padding(0)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.defaultMinListHeaderHeight, 0)
    }

    var empty: some View {
        ZStack {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Color(hex: 0x15151A)
                        .cornerRadius(8)
                )
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("No changes found")
                        .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
