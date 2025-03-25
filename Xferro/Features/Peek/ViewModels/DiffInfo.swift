//
//  DiffInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import Foundation
import Observation

@Observable final class DiffInfo: DiffInformation {
    var hunks: () -> [DiffHunk] = { [] }
    var allHunks: [DiffHunk]
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
        self.allHunks = hunks
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
        self.addedLinesCount = addedLinesCount
        self.deletedLinesCount = deletedLinesCount
        self.statusFileName = statusFileName
        self.hunks = { [weak self] in
            guard let self else { return [] }
            return allHunks
        }
    }

    private var __checkedState: CheckboxState = .checked

    var checkState: CheckboxState {
        get {
            __checkedState
        } set {
            for part in allHunks.flatMap(\.parts) {
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
}
