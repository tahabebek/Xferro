//
//  ChangeType.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//


import Foundation

enum ChangeType {
    case head(RepositoryInfo)
    case index(RepositoryInfo)
    case reflog(RepositoryInfo)
    case localBranches(RepositoryInfo)
    case remoteBranches(RepositoryInfo)
    case tags(RepositoryInfo)
    case stash(RepositoryInfo)
}
