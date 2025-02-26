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
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<hunk.lineCount, id: \.self) { index in
                            lineView(for: hunk.lineAtIndex(index))
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.vertical)
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

    func padding(for line: DiffLine) -> CGFloat {
        switch line.type {
        case .addition, .deletion:
            2.0
        default:
            0.0
        }
    }

    func lineNumber(_ line: Int32) -> String {
        line == -1 ? "" : line.formatted()
    }

    func color(for line: DiffLine) -> Color {
        switch line.type {
        case .addition:
            Color(hex: 0x28A745).opacity(0.3)
        case .deletion:
            Color(hex: 0xDC3545).opacity(0.3)
        default:
            Color.clear
        }
    }

    func lineView(for line: DiffLine) -> some View {
        ZStack(alignment: .leading) {
            color(for: line)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            HStack(spacing: 0) {
                Group {
                    HStack {
                        Spacer()
                        Text(lineNumber(line.oldLine))
                    }
                    HStack {
                        Spacer()
                        Text(lineNumber(line.newLine))
                    }
                }
                .monospacedDigit()
                .frame(width: 40)
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                Text(line.text)
                    .frame(height: 20)
                    .padding(.leading, 8)
                Spacer()
            }
        }
        .frame(height: 20)
    }
}
