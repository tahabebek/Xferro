//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    @Binding var file: OldNewFile
    @Binding var timeStamp: Date
    @State var intitalDiffLoadIsComplete: Bool = false

    var body: some View {
        Group {
            VStack(spacing: 0) {
                PeekViewHeader(statusFileName: file.statusFileName, countString: countString)
                    .background(Color.clear)
                    .padding(.horizontal, 8)
                Divider()
                DiffView(file: $file)
            }
            .background(Color.clear)
        }
        .background(Color(hexValue: 0x15151A))
        .cornerRadius(8)
        .onChange(of: timeStamp) {
            Task {
                await file.setDiffInfo()
            }
        }
        .task(id: timeStamp) {
            if !intitalDiffLoadIsComplete {
                intitalDiffLoadIsComplete = true
                await file.setDiffInfo()
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
