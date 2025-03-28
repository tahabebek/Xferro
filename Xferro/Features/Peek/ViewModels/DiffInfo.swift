//
//  DiffInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import Foundation
import Observation

@Observable final class DiffInfo: DiffInformation {
    var hunks: [DiffHunk]
    let oldFilePath: String?
    let newFilePath: String?
    let addedLinesCount: Int
    let deletedLinesCount: Int
    let statusFileName: String

    init(
        hunks: [DiffHunk],
        oldFilePath: String?,
        newFilePath: String?,
        addedLinesCount: Int,
        deletedLinesCount: Int,
        statusFileName: String
    ) {
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
        self.addedLinesCount = addedLinesCount
        self.deletedLinesCount = deletedLinesCount
        self.statusFileName = statusFileName
        self.hunks = hunks
        for i in 0..<hunks.count {
            hunks[i].onCheckStateChanged = { [weak self] in
                self?.overrideCheckState($0)
            }
        }
    }

    private var __checkedState: CheckboxState = .checked

    var checkState: CheckboxState {
        get {
            __checkedState
        } set {
            for part in hunks.flatMap(\.parts) {
                switch newValue {
                case .checked:
                    part.selectAll()
                case .unchecked:
                    part.unselectAll()
                case .partiallyChecked:
                    break
                }
            }

            __checkedState = newValue
        }
    }
    
    private func overrideCheckState(_ partCheckedState: CheckboxState) {
        __checkedState = if hunks.allSatisfy( { $0.checkedState == .checked }) {
            .checked
        } else if hunks.allSatisfy( { $0.checkedState == .unchecked }) {
            .unchecked
        } else {
            .partiallyChecked
        }
    }
}
