//
//  Submodule.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

class Submodule {
    private var git_submodule: OpaquePointer
    private var autorelease: Bool
    private var lock: NSRecursiveLock

    deinit {
        if self.autorelease {
            git_submodule_free(git_submodule)
        }
    }

    init(pointer: OpaquePointer, autorelease: Bool = true, lock: NSRecursiveLock) {
        self.git_submodule = pointer
        self.autorelease = autorelease
        self.lock = lock
    }

    var repository: Repository? {
        lock.lock()
        defer { lock.unlock() }
        var repo: OpaquePointer?
        if git_submodule_open(&repo, git_submodule) != 0 {
            return nil
        }
        return Repository(repo!)
    }

    lazy var owner: Repository = {
        lock.lock()
        defer { lock.unlock() }
        let r = git_submodule_owner(git_submodule)
        return Repository(r!)
    }()

    var name: String {
        return String(cString: git_submodule_name(git_submodule))
    }

    var path: String {
        return String(cString: git_submodule_path(git_submodule))
    }

    var url: String {
        return String(cString: git_submodule_url(git_submodule))
    }

    var branch: String {
        return String(cString: git_submodule_branch(git_submodule))
    }

    var headOID: OID? {
        lock.lock()
        defer { lock.unlock() }
        guard let oid = git_submodule_head_id(git_submodule)?.pointee else {
            return nil
        }
        return OID(oid)
    }

    var indexOID: OID? {
        lock.lock()
        defer { lock.unlock() }
        guard let oid = git_submodule_index_id(git_submodule)?.pointee else {
            return nil
        }
        return OID(oid)
    }

    var workingDirectoryOID: OID? {
        lock.lock()
        defer { lock.unlock() }
        guard let oid = git_submodule_wd_id(git_submodule)?.pointee else {
            return nil
        }
        return OID(oid)
    }

    @discardableResult
    func update(options: UpdateOptions, init: Bool = true, rescurse: Bool? = nil) -> Result<(), NSError> {
        lock.lock()
        defer { lock.unlock() }
        let msgBlock = options.fetchOptions.remoteCallback.messageBlock
        msgBlock?("\nClone submodule `\(self.name)`:\n")
        var gitOptions = options.toGitOptions()
        let result = git_submodule_update(git_submodule, `init` ? 1 : 0, &gitOptions)
        guard result == GIT_OK.rawValue else {
            let error = NSError(gitError: result, pointOfFailure: "git_submodule_update")
            msgBlock?(error.localizedDescription)
            return .failure(error)
        }
        if rescurse != false || self.recurseFetch != .no {
            self.repository?.eachSubmodule {
                $0.update(options: options, init: `init`, rescurse: rescurse)
                return GIT_OK.rawValue
            }
        }
        return .success(())
    }

    func sync() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return git_submodule_sync(git_submodule) == 0
    }

    func reload(force: Bool = false) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return git_submodule_reload(git_submodule, force ? 1 : 0) == 0
    }

    @discardableResult
    func clone(options: UpdateOptions) -> Result<Repository, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var repo: OpaquePointer?
        var options = options.toGitOptions()
        let result = git_submodule_clone(&repo, git_submodule, &options)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_submodule_clone"))
        }
        return .success(Repository(repo!))
    }

    var recurseFetch: Recurse {
        set {
            lock.lock()
            defer { lock.unlock() }
            git_submodule_set_fetch_recurse_submodules(self.owner.pointer, self.name, newValue.toGit())
        }
        get {
            lock.lock()
            defer { lock.unlock() }
            let r = git_submodule_fetch_recurse_submodules(git_submodule)
            return Recurse(git: r)
        }
    }
}
