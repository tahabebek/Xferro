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
    let onCheckStateChanged: () -> Void
    @ObservationIgnored var checkedState: CheckboxState = .checked
    
    var isAdditionOrDeletion: Bool {
        type == .additionOrDeletion
    }
    
    init(
        type: DiffHunkPartType,
        lines: [DiffLine],
        indexInHunk: Int,
        oldFilePath: String?,
        newFilePath: String?,
        onCheckStateChanged: @escaping () -> Void
    ) {
        self.type = type
        self.indexInHunk = indexInHunk
        self.lines = lines
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
        self.onCheckStateChanged = onCheckStateChanged
        if case .context = type {
            checkedState = .unchecked
            selectedLinesCount = 0
        } else {
            checkedState = .checked
            selectedLinesCount = lines.count
        }
        for i in self.lines.indices {
            self.lines[i].indexInPart = i
            self.lines[i].numberOfLinesInPart = lines.count
        }
    }
    var lines: [DiffLine]
    var selectedLinesCount: Int = 0

    private func updateCheckedState() {
        if case .context = type {
            return
        }

        checkedState = if lines.filter(\.isAdditionOrDeletion).allSatisfy(\.isSelected) {
            .checked
        } else if lines.filter(\.isAdditionOrDeletion).allSatisfy( { !$0.isSelected }) {
            .unchecked
        } else {
            .partiallyChecked
        }
    }


    func updateSelectedLinesCount() {
        selectedLinesCount = lines.filter(\.self.isSelected).count
    }

    func toggleLine(_ line: DiffLine) {
        if case .context = type {
            return
        }
        line.isSelected.toggle()
        updateSelectedState()
    }
    
    private func updateSelectedState() {
        updateCheckedState()
        updateSelectedLinesCount()
        onCheckStateChanged()
    }

    private func selectLine(line: DiffLine, flag: Bool) {
        if case .context = type {
            return
        }
        line.isSelected = flag
    }

    func toggle() {
        checkedState = switch checkedState {
        case .checked:
            .unchecked
        case .unchecked:
            .checked
        case .partiallyChecked:
            .checked
        }
        
        let flag = checkedState == .checked
        for line in lines {
            selectLine(line: line, flag: flag)
        }
        updateSelectedState()
    }

    func unselectAll() {
        for line in lines {
            selectLine(line: line, flag: false)
        }
        updateSelectedState()
    }

    func selectAll() {
        for line in lines {
            selectLine(line: line, flag: true)
        }
        updateSelectedState()
    }
}
