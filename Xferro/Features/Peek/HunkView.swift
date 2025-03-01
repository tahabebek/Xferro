//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    let parts: [DiffHunkPart]
    let insertionText: String
    let fileExtension: String?
    
    init(parts: [DiffHunkPart], insertionText: String, fileExtension: String? = nil) {
        self.parts = parts
        self.insertionText = insertionText
        self.fileExtension = fileExtension
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack(alignment: .center) {
                    Text(insertionText.replacingOccurrences(of: "\n", with: " "))
                        .foregroundColor(Color(hexValue: 0xADBD42)) // Hunk header in a distinguishable color
                    Spacer()
                    Text("Discard chunk")
                        .foregroundColor(Color.red.opacity(0.8))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(4)
                    Text("Stage chunk")
                        .foregroundColor(Color.green.opacity(0.8))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            Divider()
            ForEach(parts) { part in
                PartView(part: part, fileExtension: fileExtension)
            }
        }
        .padding(.bottom)
    }
}
