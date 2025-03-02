//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    let hunks: [DiffHunk]
    let addedLinesCount: Int
    let deletedLinesCount: Int

    init(hunks: [DiffHunk], addedLinesCount: Int, deletedLinesCount: Int) {
        self.hunks = hunks
        self.addedLinesCount = addedLinesCount
        self.deletedLinesCount = deletedLinesCount
    }
    
    private var fileExtension: String? {
        guard let filePath = hunks.first?.delta.oldFilePath ?? hunks.first?.delta.newFilePath else { return nil }
        let url = URL(fileURLWithPath: filePath)

        let ext = url.pathExtension.lowercased()
        return ext.isEmpty ? nil : ext
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .background(Color.clear)
                .padding(.horizontal, 8)

                ForEach(hunks) { hunk in
                    HunkView(hunk: hunk, fileExtension: fileExtension)
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

    var countString: String {
        "\(hunks.count) \(hunks.count == 1 ? "chunk" : "chunks"), \(addedLinesCount) \(addedLinesCount == 1 ? "addition" : "additions"), \(deletedLinesCount) \(deletedLinesCount == 1 ? "deletion" : "deletions")"
    }

    var header: some View {
        let fileName = hunks.first?.delta.newFilePath ?? hunks.first?.delta.oldFilePath ?? "".components(separatedBy: "/").last ?? "Changes"
        return HStack(spacing: 0) {
            VerticalHeader(title: fileName, horizontalPadding: 0.0)
                .frame(height: 36)
            Spacer()
            if hunks.count > 0 {
                Text(countString)
            }
        }
    }
}
