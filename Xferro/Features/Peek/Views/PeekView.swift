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
            if let diffInfo = file.diffInfo {
                VStack(spacing: 0) {
                    PeekViewHeader(statusFileName: file.statusFileName, countString: countString)
                        .background(Color.clear)
                        .padding(.horizontal, 8)
                    Divider()
                    switch diffInfo {
                    case _ as NoDiffInfo:
                        Text("No difference")
                            .padding()
                    case _ as BinaryDiffInfo:
                        Text("Binary")
                            .padding()
                    case _ as DiffInfo:
                        ForEach(diffInfo.hunks()) { hunk in
                            HunkView(
                                hunk: Binding<DiffHunk>(
                                    get: { hunk },
                                    set: { _ in }
                                ),
                                onDiscardPart: {
                                    file.discardPart($0)
                                },
                                onDiscardLine: {
                                    file.discardLine($0)
                                }
                            )
                        }
                    default:
                        fatalError(.invalid)
                    }
                }
                .background(Color.clear)
            } else {
                VStack(spacing: 0) {
                    PeekViewHeader(statusFileName: file.statusFileName, countString: countString)
                        .background(Color.clear)
                        .padding(.horizontal, 8)
                    Divider()
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.3),
            radius: 5,
            x: 0,
            y: 3
        )
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
