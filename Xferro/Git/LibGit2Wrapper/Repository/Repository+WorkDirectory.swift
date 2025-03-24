//
//  Repository+WorkDirectory.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension Repository {
    func hasConflicts() -> Result<Bool, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var index: OpaquePointer? = nil
        defer { git_index_free(index) }
        let result = git_repository_index(&index, self.pointer)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
        }
        let conflicts = git_index_has_conflicts(index) == 1
        return .success(conflicts)
    }

    func isEmpty() -> Result<Bool, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = git_repository_is_empty(self.pointer)
        if result == 1 { return .success(true) }
        if result == 0 { return .success(false) }
        return .failure(NSError(gitError: result, pointOfFailure: "git_repository_is_empty"))
    }

    /// Get the index for the repo. The caller is responsible for freeing the index.
    func unsafeIndex(staticLock: NSRecursiveLock? = nil) -> Result<OpaquePointer, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        var index: OpaquePointer? = nil
        let result = git_repository_index(&index, self.pointer)
        guard result == GIT_OK.rawValue && index != nil else {
            let err = NSError(gitError: result, pointOfFailure: "git_repository_index")
            return .failure(err)
        }
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return .success(index!)
    }

    func stage(path: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var dirPointer = UnsafeMutablePointer<Int8>(mutating: (path as NSString).utf8String)
        return withUnsafeMutablePointer(to: &dirPointer) { pointer in
            return unsafeIndex().flatMap { index in
                defer { git_index_free(index) }
                return Self.stage(path: path, index: index)
            }
        }
    }

    static func stage(path: String, index: OpaquePointer) -> Result<Void, NSError> {
        staticLock.lock()
        defer { staticLock.unlock() }
        var dirPointer = UnsafeMutablePointer<Int8>(mutating: (path as NSString).utf8String)
        return withUnsafeMutablePointer(to: &dirPointer) { pointer in
            var paths = git_strarray(strings: pointer, count: 1)
            let addResult = git_index_add_all(index, &paths, 0, nil, nil)
            guard addResult == GIT_OK.rawValue else {
                return .failure(NSError(gitError: addResult, pointOfFailure: "git_index_add_all"))
            }
            // write index to disk
            let writeResult = git_index_write(index)
            guard writeResult == GIT_OK.rawValue else {
                return .failure(NSError(gitError: writeResult, pointOfFailure: "git_index_write"))
            }
            return .success(())
        }
    }

    func unstage(path: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        try! GitCLI.execute(self, ["reset", "-q", "HEAD", path])
        return .success(())
    }

    func untrack(path: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var dirPointer = UnsafeMutablePointer<Int8>(mutating: (path as NSString).utf8String)
        return withUnsafeMutablePointer(to: &dirPointer) { pointer in
            var paths = git_strarray(strings: pointer, count: 1)
            return unsafeIndex().flatMap { index in
                defer { git_index_free(index) }
                let addResult = git_index_remove_all(index, &paths, nil, nil)
                guard addResult == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: addResult, pointOfFailure: "git_index_remove_all"))
                }
                // write index to disk
                let writeResult = git_index_write(index)
                guard writeResult == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: writeResult, pointOfFailure: "git_index_write"))
                }
                return .success(())
            }
        }
    }
}
