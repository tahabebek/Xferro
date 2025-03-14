//
//  DiffOption.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

typealias DiffOptions = git_diff_options

extension git_diff_options {
    init(flags: DiffOption) {
        self = git_diff_options()
        git_diff_init_options(&self, UInt32(GIT_DIFF_OPTIONS_VERSION))
        self.flags = flags.rawValue
    }

    var contextLines: UInt32 {
        get { context_lines }
        set { context_lines = newValue }
    }

    static func unwrappingOptions(
        _ options: DiffOptions?,
        callback: (UnsafePointer<git_diff_options>?) -> Int32) -> Int32
    {
        if var options {
            return withUnsafePointer(to: &options) {
                callback($0)
            }
        } else {
            return callback(nil)
        }
    }
}

struct DiffOption: OptionSet {
    let rawValue: UInt32

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    static let reverse                                          = DiffOption(rawValue: 1 << 0)
    static let includeIgnored                                   = DiffOption(rawValue: 1 << 1)
    static let recurseIgnoredDirectories                        = DiffOption(rawValue: 1 << 2)
    static let includeUntracked                                 = DiffOption(rawValue: 1 << 3)
    static let recurseUntrackedDirectories                      = DiffOption(rawValue: 1 << 4)
    static let includeUnmodified                                = DiffOption(rawValue: 1 << 5)
    static let includeTypeChanges                               = DiffOption(rawValue: 1 << 6)
    static let includeTypeChangeTrees                           = DiffOption(rawValue: 1 << 7)
    static let ignoreFilemode                                   = DiffOption(rawValue: 1 << 8)
    static let ignoreSubmodules                                 = DiffOption(rawValue: 1 << 9)
    static let ignoreCase                                       = DiffOption(rawValue: 1 << 10)
    static let includeCaseChange                                = DiffOption(rawValue: 1 << 11)
    static let disablePathSpecMatch                             = DiffOption(rawValue: 1 << 12)
    static let skipBinaryCheck                                  = DiffOption(rawValue: 1 << 13)
    static let enableFastUntrackedDirectories                   = DiffOption(rawValue: 1 << 14)
    static let updateIndex                                      = DiffOption(rawValue: 1 << 15)
    static let includeUnreadable                                = DiffOption(rawValue: 1 << 16)
    static let includeUnreadableAsUntracked                     = DiffOption(rawValue: 1 << 17)
    static let indentHeuristic                                  = DiffOption(rawValue: 1 << 18)
    static let ignoreBlankLines                                 = DiffOption(rawValue: 1 << 19)
    static let forceText                                        = DiffOption(rawValue: 1 << 20)
    static let forceBinary                                      = DiffOption(rawValue: 1 << 21)
    static let ignoreWhitespace                                 = DiffOption(rawValue: 1 << 22)
    static let ignoreWhitespaceChanges                          = DiffOption(rawValue: 1 << 23)
    static let ignoreWhitespaceEOL                              = DiffOption(rawValue: 1 << 24)
    static let showUntrackedContent                             = DiffOption(rawValue: 1 << 25)
    static let showUnmodified                                   = DiffOption(rawValue: 1 << 26)
    static let patience                                         = DiffOption(rawValue: 1 << 28)
    static let minimal                                          = DiffOption(rawValue: 1 << 29)
    static let showBinary                                       = DiffOption(rawValue: 1 << 30)
}
