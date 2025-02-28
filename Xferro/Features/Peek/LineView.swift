//
//  LineView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI

struct LineView: View {
    private static let backgroundOpacity: CGFloat = 0.3
    private static let selectedLineBackgroundOpacity: CGFloat = 0.5
    private static let hoveredLineBackgroundOpacity: CGFloat = 0.7
    private static let hoveredPartBackgroundOpacity: CGFloat = 0.7

    let line: DiffLine
    let part: DiffHunkPart
    let isFirst: Bool
    @State private var hoveredLine: Int?
    @State private var partIsHovered: Bool = false

    var body: some View {
        let _ = Self._printChanges()
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                HStack {
                    HStack(spacing: 0) {
                        // Select/Unselect all box
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            checkmarkForPart(line: line)
                            Spacer(minLength: 0)
                            Divider()
                        }
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if line.isAdditionOrDeletion {
                                part.toggle()
                            }
                        }
                        .background {
                            if line.isAdditionOrDeletion {
                                if part.hasSomeSelected {
                                    Color.accentColor.opacity(Self.hoveredPartBackgroundOpacity)
                                } else {
                                    if let hoveredLine, hoveredLine == line.indexInPart {
                                        color(line: line).opacity(Self.hoveredPartBackgroundOpacity)
                                    } else {
                                        color(line: line).opacity(Self.backgroundOpacity)
                                    }
                                }
                            }
                        }
                        .onHover {
                            partIsHovered = $0
                        }

                        HStack(spacing: 0) {
                            // Select line box
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                checkmarkForLine(line: line)
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
                                hoveredLine = line.indexInPart
                            } else {
                                hoveredLine = nil
                            }
                        }
                        .onTapGesture {
                            if line.isAdditionOrDeletion {
                                part.toggleLine(line: line)
                            }
                        }
                        .background {
                            backgroundForSelectionBox(line: line)
                        }
                    }
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                ZStack(alignment: .leading) {
                    color(line: line).opacity(Self.backgroundOpacity)
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

    func checkmarkForLine(line: DiffLine) -> some View {
        Text(line.isSelected ? "✓" : " ")
            .monospaced()
            .opacity(line.isAdditionOrDeletion ? 1 : 0)
    }

    func backgroundForSelectionBox(line: DiffLine) -> some View {
        if line.isSelected {
            if (hoveredLine != nil && hoveredLine! == line.indexInPart) ||
                partIsHovered {
                Color.accentColor.opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                Color.accentColor.opacity(Self.selectedLineBackgroundOpacity)
            }
        } else {
            if (hoveredLine != nil && hoveredLine! == line.indexInPart) ||
                partIsHovered {
                color(line: line).opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                color(line: line).opacity(Self.backgroundOpacity)
            }
        }
    }

    func checkmarkForPart(line: DiffLine) -> some View {
        let string: String = if isFirst {
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

    func color(line: DiffLine) -> Color {
        switch line.type {
        case .addition:
            Color(hex: 0x28A745)
        case .deletion:
            Color(hex: 0xDC3545)
        default:
            Color.clear
        }
    }
}
