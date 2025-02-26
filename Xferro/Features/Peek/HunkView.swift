//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import SwiftUI

struct HunkView: View {
    @State var hunk: DiffHunk?
    var body: some View {
        Group {
            if let hunk {
                VStack {
                    Text("oldlines: \(hunk.oldLines.formatted())")
                    Text("newlines: \(hunk.newLines.formatted())")
                }
                .padding()
            }
            else {
                Text("No changes.")
            }
        }
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }
}
