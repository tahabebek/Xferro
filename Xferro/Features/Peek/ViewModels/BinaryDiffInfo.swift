//
//  BinaryDiffInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/2/25.
//

import Foundation
import Observation

@Observable final class BinaryDiffInfo: DiffInformation  {
    var hunks: [DiffHunk] = []

    var statusFileName: String
    var checkState: CheckboxState

    init( statusFileName: String, checkedState: CheckboxState = .checked) {
        self.statusFileName = statusFileName
        self.checkState = checkedState
    }
    var id: String {
        "\(statusFileName).\(checkState)"
    }

    static func ==(lhs: BinaryDiffInfo, rhs: BinaryDiffInfo) -> Bool {
        lhs.id == rhs.id
    }
}

