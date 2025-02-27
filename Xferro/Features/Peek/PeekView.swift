//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    let peekViewModel: PeekViewModel
    @State private var hunks: PeekViewModel.Hunks?

    init(peekViewModel: PeekViewModel) {
        self.peekViewModel = peekViewModel
        self._hunks = State(initialValue: peekViewModel.hunks)
    }

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(showsIndicators: true) {
                if let hunks = peekViewModel.hunks, hunks.hunks.isEmpty {
                    empty
                } else if let hunks = peekViewModel.hunks?.hunks {
                    LazyVStack(spacing: 0) {
                        ForEach(hunks) { hunk in
                            HunkView(hunk: hunk)
                                .padding(.bottom, (hunk != hunks.last) ? 8 : 0)
                        }
                    }
                } else {
                    empty
                }
            }
        }
        .padding(.leading, 6)
        .id(peekViewModel.hunks?.id ?? "empty")
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
