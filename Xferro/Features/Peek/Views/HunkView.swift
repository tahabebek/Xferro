//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    let hunk: DiffHunk
    let allHunks: () -> [DiffHunk]

    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack(alignment: .center) {
                    Text(hunk.hunkHeader.replacingOccurrences(of: "\n", with: " "))
                        .foregroundColor(Color(hexValue: 0xADBD42))
                    Spacer()
                    HunkActionsView(hunk: hunk, allHunks: allHunks)
                }
                .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            Divider()
            ForEach(hunk.parts) { part in
                PartView(part: part)
            }
        }
        .padding(.bottom)
    }
}
