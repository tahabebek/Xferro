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

    init(_ hunk: DiffHunk) {
        self.hunk = hunk
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(hunk.parts.indices, id: \.self) { partIndex in
                lineView(for: partIndex)
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

    func color(lineIndex: Int, partIndex: Int) -> Color {
        switch hunk.parts[partIndex].lines[lineIndex].type {
        case .addition:
            Color(hex: 0x28A745)
        case .deletion:
            Color(hex: 0xDC3545)
        default:
            Color.clear
        }
    }

    func checkmarkForPart(lineIndex: Int, partIndex: Int) -> some View {
        let string: String = if hunk.parts[partIndex].lines[lineIndex] == hunk.parts[partIndex].lines.first! {
            if hunk.parts[partIndex].isSelected {
                "✓"
            } else if hunk.parts[partIndex].hasSomeSelected {
                "-"
            } else {
                " "
            }
        } else {
            " "
        }
        return Text(string)
            .monospaced()
            .opacity(hunk.parts[partIndex].lines[lineIndex].isAdditionOrDeletion ? 1 : 0)
    }

    func checkmarkForLine(lineIndex: Int, partIndex: Int) -> some View {
        Text(hunk.parts[partIndex].lines[lineIndex].isSelected ? "✓" : " ")
            .monospaced()
            .opacity(hunk.parts[partIndex].lines[lineIndex].isAdditionOrDeletion ? 1 : 0)
    }

    func lineView(for partIndex: Int) -> some View {
        ForEach(hunk.parts[partIndex].lines.indices, id: \.self) { lineIndex in
            lineView(for: lineIndex, partIndex: partIndex)
                .padding(.horizontal, 4)
        }
    }

    func lineView(for lineIndex: Int, partIndex: Int) -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                HStack {
                    HStack(spacing: 0) {
                        // Select/Unselect all box
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            checkmarkForPart(lineIndex: lineIndex, partIndex: partIndex)
                            Spacer(minLength: 0)
                            Divider()
                        }
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if hunk.parts[partIndex].lines[lineIndex].isAdditionOrDeletion {
                                hunk.toggleSelected(partIndex: partIndex)
                            }
                        }
                        .background {
                            if hunk.parts[partIndex].lines[lineIndex].isAdditionOrDeletion {
                                if hunk.parts[partIndex].hasSomeSelected {
                                    Color.accentColor.opacity(Self.hoveredPartBackgroundOpacity)
                                } else {
                                    if let hoveredLine, hoveredLine.partIndex == partIndex, hoveredLine.lineIndex == lineIndex {
                                        color(lineIndex: lineIndex, partIndex: partIndex).opacity(Self.hoveredPartBackgroundOpacity)
                                    } else {
                                        color(lineIndex: lineIndex, partIndex: partIndex).opacity(Self.backgroundOpacity)
                                    }
                                }
                            }
                        }
                        .onHover { flag in
                            if flag {
                                hoveredPartIndex = partIndex
                            } else {
                                hoveredPartIndex = nil
                            }
                        }

                        HStack(spacing: 0) {
                            // Select line box
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                checkmarkForLine(lineIndex: lineIndex, partIndex: partIndex)
                                Spacer(minLength: 0)
                                Divider()
                            }
                            .frame(width: 20)
                            .contentShape(Rectangle())

                            // Old line number box
                            HStack(spacing: 0) {
                                Spacer()
                                Text(lineNumber(hunk.parts[partIndex].lines[lineIndex].oldLine))
                                    .padding(.trailing, 2)
                                Divider()
                            }
                            .frame(width: 40)

                            // New line number box
                            HStack(spacing: 0) {
                                Spacer()
                                Text(lineNumber(hunk.parts[partIndex].lines[lineIndex].newLine))
                                    .padding(.trailing, 2)
                                Divider()
                            }
                            .frame(width: 40)
                        }
                        .onHover { flag in
                            if flag {
                                hoveredLine = HoveredLine(partIndex: partIndex, lineIndex: lineIndex)
                            } else {
                                hoveredLine = nil
                            }
                        }
                        .onTapGesture {
                            if hunk.parts[partIndex].lines[lineIndex].isAdditionOrDeletion {
                                hunk.toggleSelected(lineIndex: lineIndex, partIndex: partIndex)
                            }
                        }
                        .background {
                            backgroundForSelectionBox(lineIndex: lineIndex, partIndex: partIndex)
                        }
                    }
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                ZStack(alignment: .leading) {
                    color(lineIndex: lineIndex, partIndex: partIndex).opacity(Self.backgroundOpacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                    Text(hunk.parts[partIndex].lines[lineIndex].text)
                        .font(.body)
                        .frame(height: 20)
                        .padding(.leading, 8)
                }
                Spacer()
            }
        }
        .frame(height: 20)
    }

    func backgroundForSelectionBox(lineIndex: Int, partIndex: Int) -> some View {
        if hunk.parts[partIndex].lines[lineIndex].isSelected {
            if (hoveredLine != nil && hoveredLine!.partIndex == partIndex && hoveredLine!.lineIndex == lineIndex) ||
            (hoveredPartIndex != nil && hoveredPartIndex! == partIndex) {
                Color.accentColor.opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                Color.accentColor.opacity(Self.selectedLineBackgroundOpacity)
            }
        } else {
            if (hoveredLine != nil && hoveredLine!.partIndex == partIndex && hoveredLine!.lineIndex == lineIndex) ||
                (hoveredPartIndex != nil && hoveredPartIndex! == partIndex) {
                color(lineIndex: lineIndex, partIndex: partIndex).opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                color(lineIndex: lineIndex, partIndex: partIndex).opacity(Self.backgroundOpacity)
            }
        }
    }
}
