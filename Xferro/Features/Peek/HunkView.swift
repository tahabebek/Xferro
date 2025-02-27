//
//  HunkView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import SwiftUI

struct HunkView: View {
    static let backgroundOpacity: CGFloat = 0.3
    static let selectedLineBackgroundOpacity: CGFloat = 0.5
    static let hoveredLineBackgroundOpacity: CGFloat = 0.7
    static let hoveredPartBackgroundOpacity: CGFloat = 0.7
    struct HoveredLine: Equatable {
        let partIndex: Int
        let lineIndex: Int
    }
    @State var hunk: DiffHunk
    @State var hoveredLine: HoveredLine?
    @State var hoveredPartIndex: Int?

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(hunk.parts) { part in
                lineView(for: part)
            }
        }
        .padding(.vertical)
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
        .animation(.default, value: hoveredLine)
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

    func color(line: DiffLine, part: DiffHunk.DiffHunkPart) -> Color {
        switch line.type {
        case .addition:
            Color(hex: 0x28A745)
        case .deletion:
            Color(hex: 0xDC3545)
        default:
            Color.clear
        }
    }

    func checkmarkForPart(line: DiffLine, part: DiffHunk.DiffHunkPart) -> some View {
        let string: String = if line == part.lines.first! {
            if part.isSelected {
                "✓"
            } else if part.hasSomeSelected {
                "-"
            } else {
                " "
            }
        } else {
            " "
        }
        return Text(string)
            .monospaced()
            .opacity(line.isAdditionOrDeletion ? 1 : 0)
    }

    func checkmarkForLine(line: DiffLine, part: DiffHunk.DiffHunkPart) -> some View {
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
            HStack(spacing: 0) {
                HStack {
                    HStack(spacing: 0) {
                        // Select/Unselect all box
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            checkmarkForPart(line: line, part: part)
                            Spacer(minLength: 0)
                            Divider()
                        }
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if line.isAdditionOrDeletion {
                                hunk.toggleSelected(partIndex: part.index)
                            }
                        }
                        .background {
                            if line.isAdditionOrDeletion {
                                if part.hasSomeSelected {
                                    Color.accentColor.opacity(Self.hoveredPartBackgroundOpacity)
                                } else {
                                    if let hoveredLine, hoveredLine.partIndex == part.index, hoveredLine.lineIndex == line.index {
                                        color(line: line, part: part).opacity(Self.hoveredPartBackgroundOpacity)
                                    } else {
                                        color(line: line, part: part).opacity(Self.backgroundOpacity)
                                    }
                                }
                            }
                        }
                        .onHover { flag in
                            if flag {
                                hoveredPartIndex = part.index
                            } else {
                                hoveredPartIndex = nil
                            }
                        }

                        HStack(spacing: 0) {
                            // Select line box
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                checkmarkForLine(line: line, part: part)
                                Spacer(minLength: 0)
                                Divider()
                            }
                            .frame(width: 20)
                            .contentShape(Rectangle())

                            // Old line number box
                            HStack(spacing: 0) {
                                Spacer()
                                Text(lineNumber(line.oldLine))
                                    .padding(.trailing, 2)
                                Divider()
                            }
                            .frame(width: 40)

                            // New line number box
                            HStack(spacing: 0) {
                                Spacer()
                                Text(lineNumber(line.newLine))
                                    .padding(.trailing, 2)
                                Divider()
                            }
                            .frame(width: 40)
                        }
                        .onHover { flag in
                            if flag {
                                hoveredLine = HoveredLine(partIndex: part.index, lineIndex: line.index)
                            } else {
                                hoveredLine = nil
                            }
                        }
                        .onTapGesture {
                            if line.isAdditionOrDeletion {
                                hunk.toggleSelected(lineIndex: line.index, partIndex: part.index)
                            }
                        }
                        .background {
                            backgroundForSelectionBox(line: line, part: part)
                        }
                    }
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                ZStack(alignment: .leading) {
                    color(line: line, part: part).opacity(Self.backgroundOpacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                    Text(line.text)
                        .font(.body)
                        .frame(height: 20)
                        .padding(.leading, 8)
                }
                Spacer()
            }
        }
        .frame(height: 20)
    }

    func backgroundForSelectionBox(line: DiffLine, part: DiffHunk.DiffHunkPart) -> some View {
        if line.isSelected {
            if (hoveredLine != nil && hoveredLine!.partIndex == part.index && hoveredLine!.lineIndex == line.index) ||
                (hoveredPartIndex != nil && hoveredPartIndex! == part.index) {
                Color.accentColor.opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                Color.accentColor.opacity(Self.selectedLineBackgroundOpacity)
            }
        } else {
            if (hoveredLine != nil && hoveredLine!.partIndex == part.index && hoveredLine!.lineIndex == line.index) ||
                (hoveredPartIndex != nil && hoveredPartIndex! == part.index) {
                color(line: line, part: part).opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                color(line: line, part: part).opacity(Self.backgroundOpacity)
            }
        }
    }
}
