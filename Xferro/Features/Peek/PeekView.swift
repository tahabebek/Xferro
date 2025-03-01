//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    let hunks: [DiffHunk]

    init(hunks: [DiffHunk]) {
        self.hunks = hunks
    }
    
    // Extract file extension from the path if available
    private var fileExtension: String? {
        guard let filePath = hunks.first?.filePath else { return nil }
        let url = URL(fileURLWithPath: filePath)

        // Get the file extension and ensure it's non-empty
        let ext = url.pathExtension.lowercased()
        return ext.isEmpty ? nil : ext
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .background(Color.clear)
                .padding(.horizontal, 8)

                ForEach(hunks) { hunk in
                    HunkView(
                        parts: hunk.parts, 
                        insertionText: hunk.insertionText, 
                        fileExtension: fileExtension
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
        }
        .background(Color.clear)
    }

    var empty: some View {
        ZStack {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Color(hexValue: 0x15151A)
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

    var header: some View {
        let fileName = hunks.first?.filePath.components(separatedBy: "/").last ?? "Changes"
        return VerticalHeader(title: fileName, horizontalPadding: 0.0)
            .frame(height: 36)
    }
}
