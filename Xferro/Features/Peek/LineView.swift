//
//  LineView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import SwiftUI
import RegexBuilder

struct LineView: View {
    private static let backgroundOpacity: CGFloat = 0.3
    private static let selectedLineBackgroundOpacity: CGFloat = 0.5
    private static let hoveredLineBackgroundOpacity: CGFloat = 0.7
    private static let hoveredPartBackgroundOpacity: CGFloat = 0.7

    @State private var hoveredLine: Int?
    @State private var partIsHovered: Bool = false
    @State var isAdditionOrDeletion: Bool
    @State private var hasSomeSelected: Bool
    @State private var isLineSelected: Bool
    @State private var isPartSelected: Bool
    private let isFirst: Bool
    private let indexInPart: Int
    private let newLine: Int
    private let oldLine: Int
    private let text: String
    private let lineType: DiffLineType
    private let onTogglePart: () -> Void
    private let onToggleLine: () -> Void

    init(
        line: DiffLine,
        part: DiffHunkPart,
        isFirst: Bool,
        onTogglePart: @escaping () -> Void,
        onToggleLine: @escaping () -> Void
    ) {
        self._isAdditionOrDeletion = State(initialValue: line.isAdditionOrDeletion)
        self._isPartSelected = State(initialValue: part.isSelected)
        self._hasSomeSelected = State(initialValue: part.hasSomeSelected)
        self._isLineSelected = State(initialValue: line.isSelected)
        self.isFirst = isFirst
        self.indexInPart = line.indexInPart
        self.newLine = Int(line.newLine)
        self.oldLine = Int(line.oldLine)
        self.text = line.text
        self.lineType = line.type
        self.onToggleLine = onToggleLine
        self.onTogglePart = onTogglePart
    }

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                HStack {
                    HStack(spacing: 0) {
                        // Select/Unselect all box
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            checkmarkForPart()
                            Spacer(minLength: 0)
                            Divider()
                        }
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isAdditionOrDeletion {
                                onTogglePart()
                            }
                        }
                        .background {
                            if isAdditionOrDeletion {
                                if hasSomeSelected {
                                    Color.accentColor.opacity(Self.hoveredPartBackgroundOpacity)
                                } else {
                                    if let hoveredLine, hoveredLine == indexInPart {
                                        color().opacity(Self.hoveredPartBackgroundOpacity)
                                    } else {
                                        color().opacity(Self.backgroundOpacity)
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
                                checkmarkForLine()
                                Spacer(minLength: 0)
                                Divider()
                            }
                            .frame(width: 20)
                            .contentShape(Rectangle())

                            // Old line number box
                            HStack(spacing: 0) {
                                Spacer()
                                Text(lineNumber(oldLine))
                                    .padding(.trailing, 2)
                                Divider()
                            }
                            .frame(width: 40)

                            // New line number box
                            HStack(spacing: 0) {
                                Spacer()
                                Text(lineNumber(newLine))
                                    .padding(.trailing, 2)
                                Divider()
                            }
                            .frame(width: 40)
                        }
                        .onHover { flag in
                            if flag {
                                hoveredLine = indexInPart
                            } else {
                                hoveredLine = nil
                            }
                        }
                        .onTapGesture {
                            if isAdditionOrDeletion {
                                onToggleLine()
                            }
                        }
                        .background {
                            backgroundForSelectionBox()
                        }
                    }
                }
                .font(.callout)
                .monospacedDigit()
                .frame(height: 20)
                .minimumScaleFactor(0.75)
                ZStack(alignment: .leading) {
                    color().opacity(Self.backgroundOpacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: 20)
                    Text(text)
                        .font(.body.monospaced())
                        .frame(height: 20)
                        .padding(.leading, 8)
                }
                Spacer()
            }
        }
        .frame(height: 20)
    }

    func checkmarkForLine() -> some View {
        Text(isLineSelected ? "✓" : " ")
            .monospaced()
            .opacity(isAdditionOrDeletion ? 1 : 0)
    }

    func backgroundForSelectionBox() -> some View {
        if isLineSelected {
            if (hoveredLine != nil && hoveredLine! == indexInPart) ||
                partIsHovered {
                Color.accentColor.opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                Color.accentColor.opacity(Self.selectedLineBackgroundOpacity)
            }
        } else {
            if (hoveredLine != nil && hoveredLine! == indexInPart) ||
                partIsHovered {
                color().opacity(Self.hoveredLineBackgroundOpacity)
            } else {
                color().opacity(Self.backgroundOpacity)
            }
        }
    }

    func checkmarkForPart() -> some View {
        let string: String = if isFirst {
            if isPartSelected {
                "✓"
            } else if hasSomeSelected {
                "-"
            } else {
                " "
            }
        } else {
            " "
        }
        return Text(string)
            .monospaced()
            .opacity(isAdditionOrDeletion ? 1 : 0)
    }

    func padding() -> CGFloat {
        switch lineType {
        case .addition, .deletion:
            2.0
        default:
            0.0
        }
    }

    func lineNumber(_ line: Int) -> String {
        line == -1 ? "" : line.formatted()
    }

    func color() -> Color {
        switch lineType {
        case .addition:
            Color(hexValue: 0x28A745)
        case .deletion:
            Color(hexValue: 0xDC3545)
        default:
            Color.clear
        }
    }
}
