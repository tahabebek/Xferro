//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View, Equatable {
    static func == (lhs: PeekView, rhs: PeekView) -> Bool {
        lhs.deltaInfo == rhs.deltaInfo
    }

    @Binding var deltaInfo: DeltaInfo
    let head: Head

    var body: some View {
        let _ = Self._printChanges()
        Group {
            if let diffInfo = deltaInfo.diffInfo {
                VStack(spacing: 0) {
                    PeekViewHeader(statusFileName: diffInfo.statusFileName, countString: countString)
                        .background(Color.clear)
                        .padding(.horizontal, 8)
                    switch diffInfo {
                    case _ as NoDiffInfo:
                        Text("No difference")
                            .padding()
                    case _ as BinaryDiffInfo:
                        Text("Binary")
                            .padding()
                    case _ as DiffInfo:
                        ForEach(diffInfo.hunks()) { hunk in
                            HunkView(hunk: Binding<DiffHunk>(
                                get: { hunk },
                                set: { _ in }
                            ), allHunks: diffInfo.hunks)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    default:
                        fatalError(.invalid)
                    }
                }
                .background(Color.clear)
            } else {
                VStack {
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
        .task {
            if deltaInfo.diffInfo == nil {
                await deltaInfo.setDiffInfo(head: head)
            }
        }
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
        if let diffInfo = deltaInfo.diffInfo {
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
