//
//  NoDiffInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import Foundation
import Observation

@Observable final class NoDiffInfo: DiffInformation {
    var hunks: () -> [DiffHunk] = {
        []
    }
    var statusFileName: String
    var checkState: CheckboxState

    init(statusFileName: String, checkState: CheckboxState = .checked) {
        self.statusFileName = statusFileName
        self.checkState = checkState
    }
    var id: String {
        "\(statusFileName).\(checkState)"
    }

    static func ==(lhs: NoDiffInfo, rhs: NoDiffInfo) -> Bool {
        lhs.id == rhs.id
    }
}
