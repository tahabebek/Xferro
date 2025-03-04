//
//  ChangeType.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//


import Foundation

enum ChangeType {
    case head(RepositoryViewModel)
    case index(RepositoryViewModel)
    case reflog(RepositoryViewModel)
    case localBranches(RepositoryViewModel)
    case remoteBranches(RepositoryViewModel)
    case tags(RepositoryViewModel)
    case stash(RepositoryViewModel)
}