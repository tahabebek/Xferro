//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View, Equatable {
    static func == (lhs: PeekView, rhs: PeekView) -> Bool {
        lhs.peekInfo == rhs.peekInfo
    }
    
    let peekInfo: PeekViewModel

    var body: some View {
        let _ = Self._printChanges()
        VStack(spacing: 0) {
            PeekViewHeader(statusFileName: peekInfo.statusFileName, countString: countString)
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
        case .noDifference, .binary:
            ""
        case .diff(let diff):
            "\(diff.hunks.count) \(diff.hunks.count == 1 ? "chunk" : "chunks"), \(diff.addedLinesCount) \(diff.addedLinesCount == 1 ? "addition" : "additions"), \(diff.deletedLinesCount) \(diff.deletedLinesCount == 1 ? "deletion" : "deletions")"
        }
    }
}
