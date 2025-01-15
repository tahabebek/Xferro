//
//  CleanOptions.swift
//  SwiftGit2
//
//  Created by Whirlwind on 2019/8/13.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation

struct CleanOptions: OptionSet {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let force          = CleanOptions(rawValue: 1 << 0)
    static let directory      = CleanOptions(rawValue: 1 << 1)
    static let includeIgnored = CleanOptions(rawValue: 1 << 2)
    static let onlyIgnored    = CleanOptions(rawValue: 1 << 3)

    static let dryRun         = CleanOptions(rawValue: 1 << 4)
}

