//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    let peekInfo: PeekInfo

    var body: some View {
        let _ = Self._printChanges()
        VStack(spacing: 0) {
            header
                .background(Color.clear)
                .padding(.horizontal, 8)
            switch peekInfo.type {
            case .noDifference:
                Text("No difference")
            case .binary:
                Text("Binary")
            case .diff(let diff):
                ForEach(diff.hunks) { hunk in
                    HunkView(hunk: hunk)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .border(Color.random())
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
        switch peekInfo.type {
        case .noDifference(let statusFileString), .binary(let statusFileString):
            ""
        case .diff(let diff):
            "\(diff.hunks.count) \(diff.hunks.count == 1 ? "chunk" : "chunks"), \(diff.addedLinesCount) \(diff.addedLinesCount == 1 ? "addition" : "additions"), \(diff.deletedLinesCount) \(diff.deletedLinesCount == 1 ? "deletion" : "deletions")"
        }
    }

    var header: some View {
        HStack(spacing: 0) {
            VerticalHeader(title: peekInfo.statusFileName, horizontalPadding: 0.0)
                .frame(height: 36)
            Spacer()
            Text(countString)
        }
    }
}
