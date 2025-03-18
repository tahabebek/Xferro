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
    let onUpdateSelectedLines: () -> Void

    init(
        type: DiffHunkPartType,
        lines: [DiffLine],
        indexInHunk: Int,
        oldFilePath: String?,
        newFilePath: String?,
        onUpdateSelectedLines: @escaping () -> Void
    ) {
        self.type = type
        self.indexInHunk = indexInHunk
        self.lines = lines
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
        self.onUpdateSelectedLines = onUpdateSelectedLines
        if case .context = type {
            isSelected = false
        } else {
            isSelected = true
            updateSelectedLinesCount()
            updateIsSelected()
            onUpdateSelectedLines()
        }
        for i in self.lines.indices {
            self.lines[i].indexInPart = i
            self.lines[i].numberOfLinesInPart = lines.count
        }
    }
    var lines: [DiffLine]
    var isSelected: Bool
    var selectedLinesCount: Int = 0


    func updateIsSelected() {
        if case .context = type {
            fatalError(.invalid)
        }

        isSelected = lines.allSatisfy(\.isSelected)
    }


    func updateSelectedLinesCount() {
        selectedLinesCount = lines.filter(\.self.isSelected).count
    }

    func toggleLine(_ line: DiffLine) {
        if case .context = type {
            fatalError(.invalid)
        }
        line.isSelected.toggle()
        updateIsSelected()
        updateSelectedLinesCount()
        onUpdateSelectedLines()
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
        updateIsSelected()
        updateSelectedLinesCount()
        onUpdateSelectedLines()
    }
}
