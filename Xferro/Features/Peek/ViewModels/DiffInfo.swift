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

    var checkState: CheckboxState {
        get {
            let lines = allHunks.flatMap(\.parts).filter { $0.type != .context }.flatMap(\.lines)
            let selectedLinesCount = lines.filter(\.isSelected).count
            if selectedLinesCount == 0 {
                return .unchecked
            } else if selectedLinesCount == lines.count {
                return .checked
            } else {
                return .partiallyChecked
            }
        } set {
            for line in allHunks.flatMap(\.parts).filter({ $0.type != .context }).flatMap(\.lines) {
                switch newValue {
                case .checked:
                    line.isSelected = true
                case .unchecked:
                    line.isSelected = false
                case .partiallyChecked:
                    break
                }
            }
        }
    }
}
