//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/2/25.
//

import Foundation
import Observation

@Observable final class PeekViewModel: Equatable {
    @Observable final class DiffViewModel: Equatable {
        let hunks: [DiffHunk]
        let addedLinesCount: Int
        let deletedLinesCount: Int
        let statusFileName: String

        init(hunks: [DiffHunk], addedLinesCount: Int, deletedLinesCount: Int, statusFileName: String) {
//            print("init DiffViewModel")
            self.hunks = hunks
            self.addedLinesCount = addedLinesCount
            self.deletedLinesCount = deletedLinesCount
            self.statusFileName = statusFileName
        }

        deinit {
//            print("deinit DiffViewModel")
        }
        
        static func == (lhs: PeekViewModel.DiffViewModel, rhs: PeekViewModel.DiffViewModel) -> Bool {
            lhs.hunks == rhs.hunks &&
            lhs.addedLinesCount == rhs.addedLinesCount &&
            lhs.deletedLinesCount == rhs.deletedLinesCount &&
            lhs.statusFileName == rhs.statusFileName
        }
    }
    enum PeekInfoType: Equatable {
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
//        print("init PeekViewModel")
        self.type = type
    }

    deinit {
//        print("deinit PeekViewModel")
    }
    
    static func == (lhs: PeekViewModel, rhs: PeekViewModel) -> Bool {
        lhs.type == rhs.type
    }
}
