//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/2/25.
//

import Foundation
import Observation

@Observable final class PeekViewModel {
    @Observable final class DiffViewModel {
        let hunks: [DiffHunk]
        let addedLinesCount: Int
        let deletedLinesCount: Int
        let statusFileName: String

        init(hunks: [DiffHunk], addedLinesCount: Int, deletedLinesCount: Int, statusFileName: String) {
            self.hunks = hunks
            self.addedLinesCount = addedLinesCount
            self.deletedLinesCount = deletedLinesCount
            self.statusFileName = statusFileName
        }
    }
    enum PeekInfoType {
        case noDifference(statusFileName: String)
        case binary(statusFileName: String)
        case diff(DiffViewModel)
    }
    var type: PeekInfoType

    var statusFileName: String {
        switch type {
        case .noDifference(let statusFileName), .binary(let statusFileName):
            statusFileName
        case .diff(let diff):
            diff.statusFileName
        }
    }

    init(type: PeekInfoType) {
        self.type = type
    }
}
