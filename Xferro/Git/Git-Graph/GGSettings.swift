//
//  GGSettings.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGSettings {
    let debug: Bool
    let includeRemote: Bool
    let branchOrder: GGBranchOrder
    let branches: GGBranchSettings
    let mergePatterns: GGMergePatterns

    init(
        debug: Bool = false,
        includeRemote: Bool = true,
        branchOrder: GGBranchOrder,
        branches: GGBranchSettings,
        mergePatterns: GGMergePatterns
    ) {
        self.debug = debug
        self.includeRemote = includeRemote
        self.branchOrder = branchOrder
        self.branches = branches
        self.mergePatterns = mergePatterns
    }
}
