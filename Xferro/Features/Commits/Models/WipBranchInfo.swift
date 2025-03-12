//
//  WipBranchInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//


import Foundation

struct WipBranchInfo: Identifiable {
    var id: String {
        branch.name + branch.commit.oid.description
    }
    let branch: Branch
    let repository: Repository
    let head: Head
}
