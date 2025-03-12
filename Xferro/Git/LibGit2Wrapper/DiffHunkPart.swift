//
//  DiffHunkPart.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import Foundation

@Observable final class DiffHunkPart: Identifiable {
    let id = UUID()
    
    enum DiffHunkPartType: Identifiable {
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
    var type: DiffHunkPartType
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
            self.lines[i].numberOfLinesInPart = lines.count
        }
    }
    var lines: [DiffLine]
    var isSelected: Bool {
        if case .context = type {
            return false
        } else {
            return lines.allSatisfy(\.isSelected)
        }
    }
    var selectedLinesCount: Int {
        lines.filter(\.isSelected).count
    }

    func toggleLine(line: DiffLine) {
        if case .context = type {
            fatalError(.invalid)
        }
        line.isSelected.toggle()
    }

    private func selectLine(line: DiffLine, flag: Bool) {
        if case .context = type {
            fatalError(.invalid)
        }
        line.isSelected = flag
    }

    func toggle() {
        let flag = !isSelected
        for line in lines {
            selectLine(line: line, flag: flag)
        }
    }
}
