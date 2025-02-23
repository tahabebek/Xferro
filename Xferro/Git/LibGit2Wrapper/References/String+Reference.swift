//
//  String+Reference.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

extension String {
    static let tagPrefix = "refs/tags/"
    static let branchPrefix = "refs/heads/"
    static let remotePrefix = "refs/remotes/"
    static let wipPrefix = "refs/heads/\(WipWorktree.wipBranchesPrefix)"

    var longBranchRef: String {
        return self.isLongRef ? self : "\(String.branchPrefix)\(self)"
    }

    var longTagRef: String {
        return self.isLongRef ? self : "\(String.tagPrefix)\(self)"
    }

    var isLongRef: Bool {
        return self.hasPrefix("refs/")
    }

    var isBranchRef: Bool {
        return self.hasPrefix(.branchPrefix)
    }

    var isTagRef: Bool {
        return self.hasPrefix(.tagPrefix)
    }

    var isRemoteRef: Bool {
        return self.hasPrefix(.remotePrefix)
    }

    var isWipRef: Bool {
        return self.hasPrefix(.wipPrefix)
    }

    var isHEAD: Bool {
        return self == "HEAD"
    }

    var shortRef: String {
        if !isLongRef { return self }
        let pieces = self.split(separator: "/")
        if pieces.count < 3 { return self }
        return pieces.dropFirst(2).joined(separator: "/")
    }
}
