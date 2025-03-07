//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/2/25.
//

import Foundation
import Observation

@Observable final class PeekViewModel: Equatable {
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

    var allHunks: () -> [DiffHunk] = { [] }

    init(type: PeekInfoType) {
        print("init PeekViewModel")
        self.type = type
        self.allHunks = {
            guard case .diff(let diff) = type else {
                return []
            }
            return diff.hunks
        }
    }

    deinit {
        print("deinit PeekViewModel")
    }
    
    static func == (lhs: PeekViewModel, rhs: PeekViewModel) -> Bool {
        lhs.type == rhs.type
    }
}
