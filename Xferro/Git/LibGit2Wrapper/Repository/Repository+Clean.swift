//
//  Repository+Clean.swift
//  SwiftGit2
//
//  Created by Whirlwind on 2019/8/13.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation

extension Repository {
    /*
     The git clean command removes untracked files from your working directory. Specifically:

     It deletes files that aren't tracked by Git (files that have never been added to the repository with git add)
     By default, it doesn't remove files that are ignored via .gitignore
     It's useful for cleaning up build artifacts, temporary files, or other generated content

     The basic command is git clean -f (force is required since it's a destructive operation). Common options include:

     -n or --dry-run: Show what would be deleted without actually deleting
     -d: Remove untracked directories too, not just files
     -x: Remove ignored files as well
     -i: Interactive mode, which asks for confirmation before each deletion

     This is particularly helpful when you want to return to a clean state, removing all generated files or test artifacts that might interfere with future builds or tests.
     Since this operation permanently deletes files that aren't in Git, it can't be undone with Git commands, which is why it requires the force flag by default.
     */
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
                    try? FileManager.removeItem(url)
                }
            }
            return .success(s)
        }
        return result
    }
}
