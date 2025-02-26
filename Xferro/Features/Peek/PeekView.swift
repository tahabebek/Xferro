//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    @Environment(PeekViewModel.self) var peekViewModel

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(showsIndicators: true) {
                if peekViewModel.hunks.isEmpty {
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
                } else {
                    LazyVStack {
                        Color.red
                            .frame(height: 000.1)
                            .id("top")
                        ForEach(peekViewModel.hunks) { hunk in
                            HunkView(hunk)
                        }
                    }
                }
            }
            .onChange(of: peekViewModel.hunks) { _, newValue in
                scrollView.scrollTo("top", anchor: .top)
            }
        }
        .padding(.leading, 6)
    }
}
