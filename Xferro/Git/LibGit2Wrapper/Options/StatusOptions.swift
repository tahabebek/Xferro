//
//  StatusOptions.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

struct StatusOptions: OptionSet {
    let rawValue: UInt32

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    static let includeUntracked              = StatusOptions(rawValue: 1 << 0)
    static let includeIgnored                = StatusOptions(rawValue: 1 << 1)
    static let includeUnmodified             = StatusOptions(rawValue: 1 << 2)
    static let excludeSubmodules             = StatusOptions(rawValue: 1 << 3)
    static let recurseUntrackedDirs          = StatusOptions(rawValue: 1 << 4)
    static let disablePathspecMatch          = StatusOptions(rawValue: 1 << 5)
    static let recurseIgnoredDirs            = StatusOptions(rawValue: 1 << 6)
    static let renamesHeadToIndex            = StatusOptions(rawValue: 1 << 7)
    static let renamesIndexToWorkdir         = StatusOptions(rawValue: 1 << 8)
    static let sortCaseSensitively           = StatusOptions(rawValue: 1 << 9)
    static let sortCaseInsensitively         = StatusOptions(rawValue: 1 << 10)
    static let renamesFromRewrites           = StatusOptions(rawValue: 1 << 11)
    static let noRefresh                     = StatusOptions(rawValue: 1 << 12)
    static let updateIndex                   = StatusOptions(rawValue: 1 << 13)
    static let includeUnreadable             = StatusOptions(rawValue: 1 << 14)
    static let includeUnreadableAsUntracked  = StatusOptions(rawValue: 1 << 15)
}
