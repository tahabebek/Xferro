//
//  GGBranchInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGBranchSpan: Codable, CustomDebugStringConvertible, Equatable {
    var start: Int?
    var end: Int?

    init(_ start: Int? = nil, _ end: Int? = nil) {
        self.start = start
        self.end = end
    }

    var debugDescription: String {
        "(\(start?.formatted() ?? "None"), \(end?.formatted() ?? "None"))"
    }
}

struct GGBranchInfo: Codable, Equatable, Identifiable {
    var id: String {
        name + target.description
    }
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
    var verticalSpan: GGBranchSpan

    init(
        target: OID,
        mergeTarget: OID? = nil,
        sourceBranch: Int? = nil,
        targetBranch: Int? = nil,
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
        self.sourceBranch = sourceBranch
        self.targetBranch = targetBranch
        self.name = name
        self.persistence = persistence
        self.isRemote = isRemote
        self.isMerged = isMerged
        self.isTag = isTag
        self.visual = visual
        self.verticalSpan = GGBranchSpan(endIndex, nil)
    }

    init(
        target: OID,
        mergeTarget: OID? = nil,
        sourceBranch: Int? = nil,
        targetBranch: Int? = nil,
        name: String,
        persistence: UInt8,
        isRemote: Bool,
        isMerged: Bool,
        isTag: Bool,
        visual: GGBranchVis,
        verticalSpan: GGBranchSpan
    ) {
        self.target = target
        self.mergeTarget = mergeTarget
        self.sourceBranch = sourceBranch
        self.targetBranch = targetBranch
        self.name = name
        self.persistence = persistence
        self.isRemote = isRemote
        self.isMerged = isMerged
        self.isTag = isTag
        self.visual = visual
        self.verticalSpan = verticalSpan
    }
}

struct GGBranchVis: Codable, Equatable {
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

    init(
        orderGroup: Int,
        targetOrderGroup: Int? = nil,
        sourceOrderGroup: Int? = nil,
        termColor: UInt8,
        svgColor: String,
        column: Int? = nil
    ) {
        self.orderGroup = orderGroup
        self.targetOrderGroup = targetOrderGroup
        self.sourceOrderGroup = sourceOrderGroup
        self.termColor = termColor
        self.svgColor = svgColor
        self.column = column
    }
}
