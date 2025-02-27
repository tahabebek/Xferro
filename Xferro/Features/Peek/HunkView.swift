//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    @State var hunk: DiffHunk

    init(_ hunk: DiffHunk) {
        self.hunk = hunk
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(hunk.parts.indices, id: \.self) { index in
                lineView(for: hunk.parts[index])
            }
        }
        .padding(.vertical)
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

    func checkmarkForLine(_ line: DiffLine, part: DiffHunk.DiffHunkPart) -> some View {
        Text((part.isSelected && line == part.lines.first!) ? "✓" : " ")
            .monospaced()
            .opacity(line.isAdditionOrDeletion ? 1 : 0)
    }

    func checkmarkForLine(_ line: DiffLine) -> some View {
        Text(line.isSelected ? "✓" : " ")
            .monospaced()
            .opacity(line.isAdditionOrDeletion ? 1 : 0)
    }

    func lineView(for part: DiffHunk.DiffHunkPart) -> some View {
        ForEach(part.lines) { line in
            lineView(for: line, part: part)
                .padding(.horizontal, 4)
        }
    }

    func lineView(for line: DiffLine, part: DiffHunk.DiffHunkPart) -> some View {
        ZStack(alignment: .leading) {
            color(for: line)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        checkmarkForLine(line, part: part)
                        Divider()
                    }
                    .frame(width: 20)
                    HStack(spacing: 0) {
                        Spacer()
                        checkmarkForLine(line)
                        Divider()
                    }
                    .frame(width: 20)
                    HStack(spacing: 0) {
                        Spacer()
                        Text(lineNumber(line.oldLine))
                            .padding(.trailing, 2)
                        Divider()
                    }
                    .frame(width: 40)
                    HStack(spacing: 0) {
                        Spacer()
                        Text(lineNumber(line.newLine))
                            .padding(.trailing, 2)
                        Divider()
                    }
                    .frame(width: 40)
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                .border(.red)
                Text(line.text)
                    .font(.body)
                    .frame(height: 20)
                    .padding(.leading, 8)
                Spacer()
            }
        }
        .frame(height: 20)
    }
}
