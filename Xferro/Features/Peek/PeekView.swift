//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    @State var peekViewModel: PeekViewModel

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(showsIndicators: true) {
                if let hunks = peekViewModel.hunks, hunks.hunks.isEmpty {
                    empty
                } else if let hunks = peekViewModel.hunks?.hunks {
                    LazyVStack(spacing: 0) {
                        Color.red
                            .frame(height: peekViewModel.randomValue)
                            .id("top")
                        ForEach(hunks) { hunk in
                            HunkView(hunk: hunk)
//                                .padding(.bottom, (hunk != hunks.last) ? 8 : 0)
                        }
                    }
                } else {
                    empty
                }
            }
            .onChange(of: peekViewModel.hunks) { _, newValue in
                scrollView.scrollTo("top", anchor: .top)
            }
        }
        .padding(.leading, 6)
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
