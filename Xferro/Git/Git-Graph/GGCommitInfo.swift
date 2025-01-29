//
//  GGCommitInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGCommitInfo {
    let oid: OID
    let isMerge: Bool
    let parents: [OID]
    var children: [OID]
    var branches: [Int]
    var tags: [Int]
    var branchTrace: Int?

    init(commit: Commit) {
        self.oid = commit.oid
        self.isMerge = commit.parents.count > 1
        self.parents = commit.parents.map { $0.oid }
        self.children = []
        self.branches = []
        self.tags = []
        self.branchTrace = nil
    }
}

