//
//  Repository+Worktree.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension Repository {
    var isWorkTree: Bool {
        lock.lock()
        defer { lock.unlock() }
        return git_repository_is_worktree(self.pointer) == 1
    }

    func worktrees() -> Result<[String], NSError> {
        lock.lock()
        defer { lock.unlock() }
        let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
        defer {
            git_strarray_dispose(pointer)
            pointer.deallocate()
        }

        let result = git_worktree_list(pointer, self.pointer)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_worktree_list"))
        }

        var names = [String]()

        let strarray = pointer.pointee
        for index in 0..<strarray.count {
            let name = strarray.strings[index]!
            names.append(String(cString: name))
        }
        return .success(names)
    }

    func HEAD(for worktree: String) -> Result<ReferenceType, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return worktree.withCString { cname in
            var pointer: OpaquePointer? = nil
            defer { git_reference_free(pointer) }
            let result = git_repository_head_for_worktree(&pointer, self.pointer, cname)
            guard result == GIT_OK.rawValue else {
                return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head_for_worktree"))
            }
            let value = referenceWithLibGit2Reference(pointer!, lock: lock)
            return .success(value)
        }
    }

    func worktree(named name: String) -> Result<Repository?, NSError> {
        lock.lock()
        defer { lock.unlock() }

        let pathResult = worktreePath(by: name)
        var path: String?
        switch pathResult {
        case .success(let thePath):
            path = thePath
        case .failure(let error):
            return .failure(error)
        }

        guard let path, let url = URL(string: path) else {
            return .success(nil)
        }

        guard let repository = try? Repository.at(url).get() else {
            return .success(nil)
        }

        guard repository.isWorkTree else {
            fatalError(.illegal)
        }

        return .success(repository)
    }

    func worktreePath(by name: String) -> Result<String?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var wtPointer: OpaquePointer? = nil

        let result = git_worktree_lookup(&wtPointer, self.pointer, name)
        if result == GIT_ENOTFOUND.rawValue {
            return .success(nil)
        }
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_worktree_lookup"))
        }

        let path = String(cString: git_worktree_path(wtPointer))
        return .success(path)
    }

    func pruneWorkTree(_ name: String, force: Bool = false) -> Result<String?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var wtPointer: OpaquePointer? = nil

        let result = git_worktree_lookup(&wtPointer, self.pointer, name)
        guard result == GIT_OK.rawValue else {
            return .success(nil)
        }

        let path = String(cString: git_worktree_path(wtPointer))

        let options = UnsafeMutablePointer<git_worktree_prune_options>.allocate(capacity: 1)
        defer { options.deallocate() }
        let optionsResult = git_worktree_prune_options_init(options, UInt32(GIT_WORKTREE_PRUNE_OPTIONS_VERSION))
        guard optionsResult == GIT_OK.rawValue else {
            return .failure(NSError(gitError: optionsResult, pointOfFailure: "git_worktree_prune_options_init"))
        }

        if force {
            options.pointee.flags = GIT_WORKTREE_PRUNE_VALID.rawValue | GIT_WORKTREE_PRUNE_LOCKED.rawValue
        } else {
            let valid = git_worktree_validate(wtPointer) == 0
            if valid {
                // libgit2 have a bug, it does not check the worktree path exists.
                var isDirectory: ObjCBool = false
                if !FileManager.fileExists(path, isDirectory: &isDirectory) || !isDirectory.boolValue {
                    options.pointee.flags = options.pointee.flags | GIT_WORKTREE_PRUNE_VALID.rawValue
                }
            }
        }

        let prunable = git_worktree_is_prunable(wtPointer, options) > 0
        if prunable {
            let result2 = git_worktree_prune(wtPointer, options)
            guard result2 == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result2, pointOfFailure: "git_worktree_prune"))
            }
            return .success(path)
        }
        return .success(nil)
    }

    func pruneWorkTrees(all: Bool = false) -> Result<[String], NSError> {
        lock.lock()
        defer { lock.unlock() }
        return self.worktrees().flatMap { names in
            var pruned = [String]()
            for name in names {
                do {
                    if let path = try pruneWorkTree(name, force: all).get() {
                        pruned.append(path)
                    }
                } catch {
                    return .failure(error as NSError)
                }
            }
            return .success(pruned)
        }
    }

    func addWorkTree(name: String, path: String) -> Result<Void, NSError> {
        let checkoutOptions  = UnsafeMutablePointer<git_checkout_options>.allocate(capacity: 1)
        defer { checkoutOptions.deallocate() }
        var result = git_checkout_options_init(checkoutOptions, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_checkout_options_init"))
        }

        let options = UnsafeMutablePointer<git_worktree_add_options>.allocate(capacity: 1)
        defer { options.deallocate() }
        result = git_worktree_add_options_init(options, UInt32(GIT_WORKTREE_ADD_OPTIONS_VERSION))
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_worktree_add_options_init"))
        }
        options.pointee.checkout_options = checkoutOptions.pointee

        var reference: OpaquePointer? = nil
        defer {
            if let reference {
                git_reference_delete(reference)
            }
        }

        var ref: OpaquePointer? = nil
        defer { git_reference_free(ref) }
        result = git_repository_head(&ref, self.pointer)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
        }
        let oid = git_reference_target(ref)
        let tmpBranch = "refs/heads/Xferro-TMP-\(UUID().uuidString.prefix(6))"
        result = git_reference_create(&reference, self.pointer, tmpBranch, oid, 0, "Xferro TMP Branch")
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_create"))
        }
        options.pointee.ref = reference

        var worktree: OpaquePointer?
        result = name.withCString { cName -> Int32 in
            path.withCString { cPath -> Int32 in
                git_worktree_add(&worktree, self.pointer, cName, cPath, options)
            }
        }
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_worktree_add"))
        }
        return .success(())
    }
}
