//
//  Repository+Config.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension Repository {
    var config: GitConfig? {
        lock.lock()
        defer { lock.unlock() }
        return GitConfig(repository: pointer)
    }

    var configPath: String? {
        lock.lock()
        defer { lock.unlock() }
        var buf = git_buf()
        defer { git_buf_dispose(&buf) }
        guard git_repository_item_path(&buf, self.pointer, GIT_REPOSITORY_ITEM_CONFIG) == 0 else { return nil }
        return String(cString: buf.ptr)
    }

    var worktreeConfigPath: String? {
        lock.lock()
        defer { lock.unlock() }
        var buf = git_buf()
        defer { git_buf_dispose(&buf) }
        guard git_repository_item_path(&buf, self.pointer, GIT_REPOSITORY_ITEM_GITDIR) == 0 else { return nil }
        let path = String(cString: buf.ptr)
        return NSString(string: path).appendingPathComponent("config.worktree")
    }
}

