//
//  HEAD.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

enum Head: Codable, Equatable {
    case branch(Branch, Commit)
    case tag(TagReference, Commit)
    case reference(Reference, Commit)

    var oid: OID {
        switch self {
        case .branch(let branch, _):
            branch.oid
        case .tag(let tagReference, _):
            tagReference.oid
        case .reference(let reference, _):
            reference.oid
        }
    }

    var name: String {
        switch self {
            case .branch(let branch, _):
            branch.name
        case .tag(let tagReference, _):
            tagReference.name
        case .reference(let reference, _):
            reference.shortName ?? reference.longName
        }
    }

    var reference: ReferenceType {
        switch self {
        case .branch(let branch, _):
            branch
        case .tag(let tagReference, _):
            tagReference
        case .reference(let reference, _):
            reference
        }
    }

    var commit: Commit {
        switch self {
            case .branch(_, let commit):
            commit
        case .tag(_, let commit):
            commit
        case .reference(_, let commit):
            commit
        }
    }

    var time: Date {
        commit.author.time
    }

    static func of(_ repository: Repository) -> Head {
        guard let headRef = try? repository.HEAD(staticLock: Repository.staticLock).get() else {
            repository.createEmptyCommit()
            let newHeadRef = repository.HEAD(staticLock: Repository.staticLock).mustSucceed(repository.gitDir)
            return getHeadWithReference(repository, newHeadRef)
        }
        return getHeadWithReference(repository, headRef)
    }

    static func of(worktree: String, in repository: Repository) -> Head {
        getHeadWithReference(repository, repository.HEAD(for: worktree).mustSucceed(repository.gitDir))
    }

    static func setHead(repository: Repository, oid: OID) -> Result<Void, NSError> {
        repository.setHEAD(oid)
    }

    static func checkout(
        repository: Repository,
        longName: String,
        _ options: CheckoutOptions? = nil
    ) -> Result<Void, NSError> {
        repository.setHEAD(longName).flatMap { repository.checkout(options) }
    }

    private static func getHeadWithReference(_ repository: Repository, _ headRef: ReferenceType) -> Head {
        let headCommit = repository.commit(
            headRef.oid,
            staticLock: Repository.staticLock
        ).mustSucceed(repository.gitDir)

        return if let branchRef = headRef as? Branch {
            .branch(branchRef, headCommit)
        } else if let tagRef = headRef as? TagReference {
            .tag(tagRef, headCommit)
        } else if let reference = headRef as? Reference {
            .reference(reference, headCommit)
        } else {
            fatalError(.impossible)
        }
    }
}

fileprivate extension Repository {
    func headIsUnborn() -> Result<Bool, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = git_repository_head_unborn(self.pointer)
        if result == 1 { return .success(true) }
        if result == 0 { return .success(false) }
        return .failure(NSError(gitError: result, pointOfFailure: "git_repository_head_unborn"))
    }

    func unbornHEAD() -> Result<UnbornBranch, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var pointer: OpaquePointer? = nil
        defer { git_reference_free(pointer) }
        let result = git_reference_lookup(&pointer, self.pointer, "HEAD")
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_lookup"))
        }
        return .success(UnbornBranch(pointer!, lock: lock)!)
    }

    /// Load the reference pointed at by HEAD.
    ///
    /// When on a branch, this will return the current `Branch`.
    func HEAD(staticLock: NSRecursiveLock? = nil) -> Result<ReferenceType, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        
        defer {
            if let staticLock {
                staticLock.unlock()
            } else {
                lock.unlock()
            }
        }
        var pointer: OpaquePointer? = nil
        defer { git_reference_free(pointer) }
        let result = git_repository_head(&pointer, self.pointer)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
        }
        let value = referenceWithLibGit2Reference(pointer!, lock: staticLock ?? lock)
        return .success(value)
    }

    /// Set HEAD to the given oid (detached).
    ///
    /// :param: oid The OID to set as HEAD.
    /// :returns: Returns a result with void or the error that occurred.
    func setHEAD(_ oid: OID) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return longOID(for: oid).flatMap { oid -> Result<Void, NSError> in
            var git_oid = oid.oid
            let result = git_repository_set_head_detached(self.pointer, &git_oid)
            guard result == GIT_OK.rawValue else {
                return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head_detached"))
            }
            return Result.success(())
        }
    }

    /// Set HEAD to the given reference.
    ///
    /// :param: name The name to set as HEAD.
    /// :returns: Returns a result with void or the error that occurred.
    func setHEAD(_ name: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var longName = name
        if !name.isLongRef {
            do {
                guard let reference = try self.reference(named: name).get() else {
                    return .failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_repository_set_head"))
                }
                longName = reference.longName
            } catch {
                return .failure(error as NSError)
            }
        }
        let result = git_repository_set_head(self.pointer, longName)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head"))
        }
        return Result.success(())
    }

    /// Check out HEAD.
    ///
    /// :param: strategy The checkout strategy to use.
    /// :param: progress A block that's called with the progress of the checkout.
    /// :returns: Returns a result with void or the error that occurred.
    func checkout(_ options: CheckoutOptions? = nil) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var opt = (options ?? CheckoutOptions()).toGit()

        let result = git_checkout_head(self.pointer, &opt)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_checkout_head"))
        }

        return Result.success(())
    }

    /// Check out the given OID.
    ///
    /// :param: oid The OID of the commit to check out.
    /// :param: strategy The checkout strategy to use.
    /// :param: progress A block that's called with the progress of the checkout.
    /// :returns: Returns a result with void or the error that occurred.
    func checkout(_ oid: OID, _ options: CheckoutOptions? = nil) -> Result<Void, NSError> {
        setHEAD(oid).flatMap { self.checkout(options) }
    }

    /// Check out the given reference.
    ///
    /// :param: longName The long name to check out.
    /// :param: strategy The checkout strategy to use.
    /// :param: progress A block that's called with the progress of the checkout.
    /// :returns: Returns a result with void or the error that occurred.
    func checkout(_ longName: String, _ options: CheckoutOptions? = nil) -> Result<Void, NSError> {
        setHEAD(longName).flatMap { self.checkout(options) }
    }
}
