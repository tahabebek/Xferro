//
//  HEAD.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

enum Head: Codable {
    case branch(Branch)
    case tag(TagReference)
    case reference(Reference)

    var oid: OID {
        switch self {
        case .branch(let branch):
            branch.oid
        case .tag(let tagReference):
            tagReference.oid
        case .reference(let reference):
            reference.oid
        }
    }

    var reference: ReferenceType {
        switch self {
        case .branch(let branch):
            branch
        case .tag(let tagReference):
            tagReference
        case .reference(let reference):
            reference
        }
    }

    static func of(_ repository: Repository) -> Head {
        guard let headRef = try? repository.HEAD().get() else {
            repository.createEmptyCommit()
            let newHeadRef = repository.HEAD().mustSucceed()
            return getHeadWithReference(newHeadRef)
        }
        return getHeadWithReference(headRef)
    }

    static func of(worktree: String, in repository: Repository) -> Head {
        getHeadWithReference(repository.HEAD(for: worktree).mustSucceed())
    }

    static func setHead(repository: Repository, oid: OID) -> Result<Void, NSError> {
        repository.setHEAD(oid)
    }

    static func checkout(repository: Repository, longName: String, _ options: CheckoutOptions? = nil) -> Result<Void, NSError> {
        repository.setHEAD(longName).flatMap { repository.checkout(options) }
    }

    private static func getHeadWithReference(_ headRef: ReferenceType) -> Head {
        if let branchRef = headRef as? Branch {
            .branch(branchRef)
        } else if let tagRef = headRef as? TagReference {
            .tag(tagRef)
        } else if let reference = headRef as? Reference {
            .reference(reference)
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
    func HEAD() -> Result<ReferenceType, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var pointer: OpaquePointer? = nil
        defer { git_reference_free(pointer) }
        let result = git_repository_head(&pointer, self.pointer)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
        }
        let value = referenceWithLibGit2Reference(pointer!, lock: lock)
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
