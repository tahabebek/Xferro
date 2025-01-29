//
//  GGBranchInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGBranchInfo {
    let target: OID
    let mergeTarget: OID?
    var sourceBranch: Int?
    var targetBranch: Int?
    var name: String
    let persistence: UInt8
    let isRemote: Bool
    let isMerged: Bool
    let isTag: Bool
    var visual: GGBranchVis
    var verticalSpan: (start: Int?, end: Int?)

    init(
        target: OID,
        mergeTarget: OID? = nil,
        name: String,
        persistence: UInt8,
        isRemote: Bool,
        isMerged: Bool,
        isTag: Bool,
        visual: GGBranchVis,
        endIndex: Int?
    ) {
        self.target = target
        self.mergeTarget = mergeTarget
        self.targetBranch = nil
        self.sourceBranch = nil
        self.name = name
        self.persistence = persistence
        self.isRemote = isRemote
        self.isMerged = isMerged
        self.isTag = isTag
        self.visual = visual
        self.verticalSpan = (endIndex, nil)
    }
}

struct GGBranchVis {
    /// The branch's column group (left to right)
    var orderGroup: Int
    /// The branch's merge target column group (left to right)
    var targetOrderGroup: Int?
    /// The branch's source branch column group (left to right)
    var sourceOrderGroup: Int?
    /// The branch's terminal color (index in 256-color palette)
    var termColor: UInt8
    /// SVG color (name or RGB in hex annotation)
    var svgColor: String
    /// The column the branch is located in
    var column: Int?

    init(orderGroup: Int, termColor: UInt8, svgColor: String) {
        self.orderGroup = orderGroup
        self.targetOrderGroup = nil
        self.sourceOrderGroup = nil
        self.termColor = termColor
        self.svgColor = svgColor
        self.column = nil
    }
}
