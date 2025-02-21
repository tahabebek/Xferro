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
    func unsafeIndex() -> Result<OpaquePointer, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var index: OpaquePointer? = nil
        let result = git_repository_index(&index, self.pointer)
        guard result == GIT_OK.rawValue && index != nil else {
            let err = NSError(gitError: result, pointOfFailure: "git_repository_index")
            return .failure(err)
        }
        return .success(index!)
    }

    func duplicateIndex(originalIndex: OpaquePointer) -> (copiedIndex: OpaquePointer, paths: [String]) {
        var newIndex: OpaquePointer?

        // Create a new in-memory index
        if git_index_new(&newIndex) != 0 || newIndex == nil {
            fatalError(GitError.getLastErrorMessage())
        }

        let unwrappedNewIndex = newIndex!
        var paths: [String] = []

        // Copy all entries from original to new index
        let entryCount = git_index_entrycount(originalIndex)
        for i in 0..<entryCount {
            guard let entry = git_index_get_byindex(originalIndex, i) else {
                fatalError(GitError.getLastErrorMessage())
            }

            guard git_index_add(unwrappedNewIndex, entry) == 0 else {
                fatalError(GitError.getLastErrorMessage())
            }

            guard let cPath = entry.pointee.path else {
                fatalError(GitError.getLastErrorMessage())
            }

            paths.append(String(cString: cPath))
        }

        return (unwrappedNewIndex, paths)
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
        RepoManager().git(self, ["reset", "-q", "HEAD", path])
        return .success(())
        // The code below didn'work, that is why git command line tool is used
//        print("Attempting to unstage: \(path)")
//
//        // Get and verify the index
//        var index: OpaquePointer?
//        var result = git_repository_index(&index, self.pointer)
//        guard result == GIT_OK.rawValue else {
//            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
//        }
//        defer { git_index_free(index) }
//
//        // Check if the file exists in the index
//        let indexEntry = git_index_get_bypath(index, path, 0)
//        print("File exists in index: \(indexEntry != nil)")
//
//        // Get and verify HEAD reference
//        var head: OpaquePointer?
//        result = git_repository_head(&head, self.pointer)
//        guard result == GIT_OK.rawValue else {
//            print("Cannot get HEAD reference")
//            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
//        }
//        defer { git_reference_free(head) }
//
//        var commit: OpaquePointer?
//        result = git_reference_peel(&commit, head, GIT_OBJECT_COMMIT)
//        guard result == GIT_OK.rawValue else {
//            print("Cannot peel HEAD to commit")
//            return .failure(NSError(gitError: result, pointOfFailure: "git_reference_peel"))
//        }
//        defer { git_object_free(commit) }
//
//        // Get the tree from HEAD
//        var tree: OpaquePointer?
//        result = git_commit_tree(&tree, commit)
//        guard result == GIT_OK.rawValue else {
//            print("Cannot get tree from HEAD commit")
//            return .failure(NSError(gitError: result, pointOfFailure: "git_commit_tree"))
//        }
//        defer { git_tree_free(tree) }
//
//        // Try to find the file in HEAD's tree
//        var entry: OpaquePointer?
//        result = git_tree_entry_bypath(&entry, tree, path)
//        if result == GIT_OK.rawValue {
//            git_tree_entry_free(entry)
//            print("File found in HEAD tree")
//             // File exists in HEAD, use reset_default
//            let cString = strdup(path)
//            defer { free(cString) }
//            let pointer = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: 1)
//            defer { pointer.deallocate() }
//            pointer.initialize(to: cString)
//            var pathspec = git_strarray(
//                strings: pointer,
//                count: 1
//            )
//
//            let result = git_reset_default(self.pointer, nil, &pathspec)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_checkout_tree"))
//            }
//
//            return .success(())
//        } else {
//            print("File not found in HEAD tree, error: \(result)")
//            // File is new, remove it from the index
//            var index: OpaquePointer?
//            result = git_repository_index(&index, self.pointer)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
//            }
//            defer { git_index_free(index) }
//
//            result = git_index_remove_bypath(index, path)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_index_remove_bypath"))
//            }
//
//            // Write the changes to disk
//            result = git_index_write(index)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_index_write"))
//            }
//        }
//
//        return .success(())
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
