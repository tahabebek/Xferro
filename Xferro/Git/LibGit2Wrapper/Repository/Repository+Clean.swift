//
//  Repository+Clean.swift
//  SwiftGit2
//
//  Created by Whirlwind on 2019/8/13.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation

extension Repository {
    #warning("check what this function does")
    func clean(_ options: CleanOptions, shouldRemove: ((String) -> Bool)? = nil) -> Result<[String], NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result: Result<[String], NSError> = status().flatMap { entries -> Result<[String], NSError> in
            let s = entries.filter({ entry -> Bool in
                if entry.status == .workTreeNew && !options.contains(.onlyIgnored) {
                    return true
                } else if entry.status == .ignored && (options.contains(.includeIgnored) || options.contains(.onlyIgnored)) {
                    return true
                }
                return false
            }).compactMap { $0.unstagedDelta?.newFile?.path }
            if !options.contains(.dryRun) {
                for path in s {
                    if let block = shouldRemove, !block(path) {
                        continue
                    }
                    let url = workDir.appendingPathComponent(path)
                    try? FileManager.removeItem(atURL: url)
                }
            }
            return .success(s)
        }
        return result
    }
}
