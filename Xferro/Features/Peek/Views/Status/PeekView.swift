//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    let file: OldNewFile
    var body: some View {
        Group {
            ScrollView {
                VStack(spacing: 0) {
                    PeekViewHeader(statusFileName: file.statusFileName, countString: countString)
                        .background(Color.clear)
                        .padding(.horizontal, 8)
                    Divider()
                    ZStack {
                        DiffView(file: file)
                        ProgressView()
                            .controlSize(.small)
                            .padding()
                            .opacity(file.diffInfo == nil ? 1 : 0)
                    }
                }
                .background(Color.clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 5,
                    x: 0,
                    y: 3
                )
            }
        }
    }

    var countString: String {
        if let diffInfo = file.diffInfo {
            switch diffInfo {
            case _ as NoDiffInfo, _ as BinaryDiffInfo:
                ""
            case let diff as DiffInfo:
                "\(diff.hunks().count) \(diff.hunks().count == 1 ? "chunk" : "chunks"), \(diff.addedLinesCount) \(diff.addedLinesCount == 1 ? "addition" : "additions"), \(diff.deletedLinesCount) \(diff.deletedLinesCount == 1 ? "deletion" : "deletions")"
            default:
                ""
            }
        } else {
            ""
        }
    }
}
