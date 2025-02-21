import Foundation

extension Repository {
    /// Load and return a list of all local branches.
    func localBranches() -> Result<[Branch], NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = references(withPrefix: .branchPrefix).map { (refs: [ReferenceType]) in
            return refs.map { $0 as! Branch }
        }
        return result
    }

    /// Load and return a list of all remote branches.
    func remoteBranches() -> Result<[Branch], NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = references(withPrefix: .remotePrefix).map { (refs: [ReferenceType]) in
            return refs.map { $0 as! Branch }
        }
        return result
    }

    /// Load the local branch with the given name (e.g., "master").
    func localBranch(named name: String) -> Result<Branch?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = reference(named: .branchPrefix + name).map { $0 as? Branch }
        return result
    }

    /// Load the remote branch with the given name (e.g., "origin/master"、"master").
    func remoteBranch(named name: String) -> Result<Branch?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        do {
            let firstItem = name.split(separator: "/").first!.lowercased()
            let remotes = try self.allRemotes().get().map(\.name)
            if remotes.contains(where: { $0.lowercased() == firstItem }) {
                let result = reference(named: .remotePrefix + name).map { $0 as? Branch }
                return result
            }
            for remote in remotes {
                let result = reference(named: .remotePrefix + remote + "/" + name).map { $0 as? Branch }
                return result
            }
            return Result.failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_reference_lookup"))
        } catch {
            return .failure(error as NSError)
        }
    }

    /// Load the local/remote branch with the given name (e.g., "master").
    func branch(named name: String) -> Result<Branch?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        if name.isLongRef {
            let result =  reference(named: name).map { $0 as? Branch }
            return result
        }
        let result = localBranch(named: name)
        if result.isSuccess {
            return result
        }
        let branch = remoteBranch(named: name)
        return branch
    }

    @discardableResult
    func createBranch(_ name: String, oid: OID, force: Bool = false) -> Result<Branch, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let branch = self.longOID(for: oid).flatMap { oid -> Result<Branch, NSError> in
            var oid = oid.oid
            var commit: OpaquePointer? = nil
            var result = git_commit_lookup(&commit, self.pointer, &oid)
            defer { git_commit_free(commit) }
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_commit_lookup"))
            }

            var newBranch: OpaquePointer? = nil
            result = git_branch_create(&newBranch, self.pointer, name.shortRef, commit, force ? 1 : 0)
            defer { git_reference_free(newBranch) }
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_branch_create"))
            }
            guard let r = Branch(newBranch!, lock: lock) else {
                return .failure(NSError(gitError: -1, pointOfFailure: "git_branch_create"))
            }
            return .success(r)
        }
        return branch
    }

    @discardableResult
    func createBranch(_ name: String, baseBranchName: String, force: Bool = false) -> Result<Branch, NSError> {
        lock.lock()
        defer { lock.unlock() }
        if !checkValid(name.longBranchRef) {
            return .failure(NSError(gitError: -1, description: "Branch name `\(name)` is invalid."))
        }
        let baseBranchResult = branch(named: baseBranchName)
        let branch: Result<Branch, NSError> = baseBranchResult.flatMap { baseBranch -> Result<Branch, NSError> in
            guard let baseBranch else {
                return .failure(NSError(gitError: -1, description: "Branch `\(baseBranchName)` not found."))
            }
            return createBranch(name, oid: baseBranch.oid, force: force)
        }
        return branch
    }

    @discardableResult
    func createBranch(_ name: String, baseTag: String, force: Bool = false) -> Result<Branch, NSError> {
        lock.lock()
        defer { lock.unlock() }
        if !checkValid(name.longBranchRef) {
            return .failure(NSError(gitError: -1, description: "Branch name `\(name)` is invalid."))
        }
        let tag = tag(named: baseTag).flatMap { tag -> Result<Branch, NSError> in
            createBranch(name, oid: tag.oid, force: force)
        }
        return tag
    }

    @discardableResult
    func createBranch(_ name: String, baseCommit: String, force: Bool = false) -> Result<Branch, NSError> {
        lock.lock()
        defer { lock.unlock() }
        if !checkValid(name.longBranchRef) {
            return .failure(NSError(gitError: -1, description: "Branch name `\(name)` is invalid."))
        }
        guard let oid = OID(string: baseCommit) else {
            return .failure(NSError(gitError: -1, description: "The commit `\(baseCommit)` is invalid."))
        }
        let branch = createBranch(name, oid: oid, force: force)
        return branch
    }

    func deleteBranch(_ name: String, remote: String, force: Bool = false) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let name = name.longBranchRef
        let branch = self.push(remote, sourceRef: "", targetRef: name, force: force)
        return branch
    }

    func deleteBranch(_ name: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let name = name.longBranchRef
        var pointer: OpaquePointer? = nil
        defer {
            git_reference_free(pointer)
        }
        var result = git_reference_lookup(&pointer, self.pointer, name)

        if result == GIT_ENOTFOUND.rawValue {
            return .success(())
        }

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_lookup"))
        }

        result = git_branch_delete(pointer)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_branch_delete"))
        }

        return .success(())
    }

    func setTrackBranch(local: String, target: String?, remote: String = "origin") -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        do {
            if let target = target {
                try self.config.set(string: remote, for: "branch.\(local).remote").get()
                try self.config.set(string: target.longBranchRef, for: "branch.\(local).merge").get()
            } else {
                try self.config.delete(keyPath: "branch.\(local).remote").get()
                try self.config.delete(keyPath: "branch.\(local).merge").get()
            }
            return .success(())
        } catch {
            return .failure(error as NSError)
        }
    }

    func trackBranch(headRef: ReferenceType) -> Result<(remote: String, merge: String)?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        guard let branch = headRef as? Branch else {
            return .failure(NSError(gitError: -1, pointOfFailure: "git_branch_lookup"))
        }
        return self.trackBranch(local: branch.name)
    }

    func trackBranch(local: String) -> Result<(remote: String, merge: String)?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        do {
            guard let remoteName = try self.config.string(for: "branch.\(local).remote").get(),
                  let mergeName = try self.config.string(for: "branch.\(local).merge").get() else {
                return .success(nil)
            }
            return .success((remote: remoteName, merge: mergeName))
        } catch {
            return Result.failure(error as NSError)
        }
    }
}
