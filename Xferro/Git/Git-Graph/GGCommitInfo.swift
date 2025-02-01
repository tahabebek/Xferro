//
//  GGCommitInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGCommitInfo: Codable {
    let oid: OID
    let shortOID: String
    let isMerge: Bool
    let parents: [OID]
    let debugParentOIDs: [String]
    let message: String
    let summary: String
    let author: Signature
    let committer: Signature
    var children: [OID]
    var debugchildrenOIDs: [String]
    var branches: [Int]
    var tags: [Int]
    var branchTrace: Int?

    init(commit: Commit) {
        self.oid = commit.oid
        self.isMerge = commit.parents.count > 1
        self.parents = commit.parents.map { $0.oid }
        self.debugParentOIDs = commit.parents.map { $0.oid.debugOID }
        self.message = commit.message
        self.summary = commit.summary
        self.author = commit.author
        self.committer = commit.committer
        self.children = []
        self.debugchildrenOIDs = []
        self.branches = []
        self.tags = []
        self.branchTrace = nil
        self.shortOID = String(commit.oid.description.prefix(7))
    }
}
