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
                        .listRowInsets(EdgeInsets())  // Remove row insets
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle()) // Use plain style to remove default styling
        .padding(0) // Remove padding
        .scrollContentBackground(.hidden) // Hide the default background
        // The following modifiers remove insets and extra padding
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
