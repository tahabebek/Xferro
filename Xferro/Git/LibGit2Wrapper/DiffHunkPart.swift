//
//  DiffHunkPart.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import Foundation

@Observable final class DiffHunkPart: Equatable, Identifiable {
    static func == (lhs: DiffHunkPart, rhs: DiffHunkPart) -> Bool {
        lhs.id == rhs.id
    }

    var id: String {
        "\(type.id).\(indexInHunk).\(isSelected).\(selectedLinesCount).\(oldFilePath ?? "").\(newFilePath ?? "")"
    }

    enum DiffHunkPartType: Equatable, Identifiable {
        var id: String {
            switch self {
            case .context:
                "context"
            case .additionOrDeletion:
                "additionOrDeletion"
            }
        }
        case context
        case additionOrDeletion
    }
    private var type: DiffHunkPartType
    let indexInHunk: Int
    let oldFilePath: String?
    let newFilePath: String?

    init(
        type: DiffHunkPartType,
        lines: [DiffLine],
        indexInHunk: Int,
        oldFilePath: String?,
        newFilePath: String?
    ) {
        self.type = type
        self.indexInHunk = indexInHunk
        self.lines = lines
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
        for i in self.lines.indices {
            self.lines[i].indexInPart = i
        }
    }
    var lines: [DiffLine]
    var isSelected = false
    var selectedLinesCount = 0

    func toggleLine(line: DiffLine) {
        if case .context = type {
            fatalError(.invalid)
        }
        line.isSelected.toggle()
        refreshSelectedStatus()
    }

    private func selectLine(line: DiffLine, flag: Bool) {
        if case .context = type {
            fatalError(.invalid)
        }
        line.isSelected = flag
    }

    func toggle() {
        for line in lines {
            selectLine(line: line, flag: !isSelected)
        }
        refreshSelectedStatus()
    }

    func refreshSelectedStatus() {
        if case .context = type {
            fatalError(.invalid)
        }
        selectedLinesCount = lines.filter(\.isSelected).count
        isSelected = lines.allSatisfy(\.isSelected)
    }
}
