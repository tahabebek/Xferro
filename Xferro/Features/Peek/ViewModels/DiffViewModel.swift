//
//  DiffViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import Foundation
import Observation

@Observable final class DiffViewModel: Equatable {
    let hunks: [DiffHunk]
    let addedLinesCount: Int
    let deletedLinesCount: Int
    let statusFileName: String

    init(hunks: [DiffHunk], addedLinesCount: Int, deletedLinesCount: Int, statusFileName: String) {
        print("init DiffViewModel")
        self.hunks = hunks
        self.addedLinesCount = addedLinesCount
        self.deletedLinesCount = deletedLinesCount
        self.statusFileName = statusFileName
    }

    deinit {
        print("deinit DiffViewModel")
    }

    static func == (lhs: DiffViewModel, rhs: DiffViewModel) -> Bool {
        lhs.hunks == rhs.hunks &&
        lhs.addedLinesCount == rhs.addedLinesCount &&
        lhs.deletedLinesCount == rhs.deletedLinesCount &&
        lhs.statusFileName == rhs.statusFileName
    }
    }
