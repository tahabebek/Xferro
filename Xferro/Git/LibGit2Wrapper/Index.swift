//
//  Index.swift
//  SwiftGit2-OSX
//
//  Created by Whirlwind on 2020/3/14.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation

class Index {
    struct Entry {
        var git_entry: git_index_entry
        init(git_entry: git_index_entry) {
            self.git_entry = git_entry
        }

        var skipWorktree: Bool {
            get {
                return self.git_entry.flags_extended & UInt16(GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue) > 0
            }
            set {
                if newValue {
                    self.git_entry.flags_extended |= UInt16(GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue)
                } else {
                    self.git_entry.flags_extended &= ~UInt16(GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue)
                }
            }
        }
    }

    var git_index: OpaquePointer
    private var lock: NSRecursiveLock

    init(git_index: OpaquePointer, lock: NSRecursiveLock) {
        self.git_index = git_index
        self.lock = lock
    }

    deinit {
        git_index_free(self.git_index)
    }

    func add(entry: Entry) -> Result<(), NSError> {
        lock.lock()
        defer { lock.unlock() }
        var git_entry = entry.git_entry
        let result = git_index_add(self.git_index, &git_entry)
        if result == GIT_OK.rawValue {
            return .success(())
        }
        return .failure(NSError(gitError: result, pointOfFailure: "git_index_add"))
    }

    func save() -> Result<(), NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = git_index_write(self.git_index)
        if result == GIT_OK.rawValue {
            return .success(())
        }
        return .failure(NSError(gitError: result, pointOfFailure: "git_index_write"))
    }

    func entry(
        by path: String,
        stage: Bool,
        block: (inout Entry) -> Result<Bool, NSError>
    )
    -> Result<(), NSError> {
        lock.lock()
        defer { lock.unlock() }
        guard let result = path.withCString({
            git_index_get_bypath(self.git_index, $0, stage ? 1 : 0)
        }) else {
            return .failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_index_get_bypath"))
        }
        var entry = Entry(git_entry: result.pointee)
        return block(&entry).flatMap { changed in
            if !changed { return .success(()) }
            return self.add(entry: entry).flatMap {
                self.save()
            }
        }
    }
}

extension Repository {
    func index() -> Result<Index, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var git_index: OpaquePointer?
        let result = git_repository_index(&git_index, self.pointer)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
        }
        return .success(Index(git_index: git_index!, lock: lock))
    }
}
