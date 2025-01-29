//
//  GGMergePatterns.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGMergePatterns {
    let patterns: [NSRegularExpression]

    static let `default` = GGMergePatterns(patterns: [
        // GitLab pull request
        try! NSRegularExpression(pattern: "^Merge branch '(.+)' into '.+'$", options: []),
        // Git default
        try! NSRegularExpression(pattern: "^Merge branch '(.+)' into .+$", options: []),
        // Git default into main branch
        try! NSRegularExpression(pattern: "^Merge branch '(.+)'$", options: []),
        // GitHub pull request
        try! NSRegularExpression(pattern: "^Merge pull request #[0-9]+ from .[^/]+/(.+)$", options: []),
        // GitHub pull request (from fork?)
        try! NSRegularExpression(pattern: "^Merge branch '(.+)' of .+$", options: []),
        // BitBucket pull request
        try! NSRegularExpression(pattern: "^Merged in (.+) \\(pull request #[0-9]+\\)$", options: [])
    ])
}
