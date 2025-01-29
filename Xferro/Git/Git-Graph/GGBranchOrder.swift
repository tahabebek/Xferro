//
//  GGBranchOrder.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

enum GGBranchOrder {
    /// Shortest branches are inserted left-most.
    /// For branches with equal length, branches ending last are inserted first.
    /// Reverse (isReverse = false): Branches ending first are inserted first.
    case shortestFirst(isReverse: Bool)

    /// Longest branches are inserted left-most.
    /// For branches with equal length, branches ending last are inserted first.
    /// Reverse (isReverse = false): Branches ending first are inserted first.
    case longestFirst(isReverse: Bool)
}
