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
        ScrollView(showsIndicators: true) {
            LazyVStack {
                if let patch = peekViewModel.patch, patch.hunkCount > 0 {
                    ForEach(0..<patch.hunkCount, id: \.self) { index in
                        HunkView(hunk: patch.hunk(at: index))
                    }
                }
            }
            .onChange(of: peekViewModel.patch) { _, _ in
                print(peekViewModel.patch?.hunkCount ?? "0")
            }
        }
    }
}
