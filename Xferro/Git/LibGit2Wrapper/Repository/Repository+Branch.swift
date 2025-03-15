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
            let remotes = try self.allRemotes().get().compactMap(\.name)
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
        guard let config else {
            return .failure(NSError(gitError: -1, pointOfFailure: "git_repository_config"))
        }
        if let target {
            config["branch.\(local).remote"] = remote
            config["branch.\(local).merge"] = target.longBranchRef
        } else {
            config["branch.\(local).remote"] = target
            config["branch.\(local).merge"] = target
        }
        return .success(())
    }

    func trackingBranchName(of branch: Branch) -> String? {
        lock.lock()
        defer { lock.unlock() }
        // Re-implement `git_branch_upstream_name` but with our cached-snapshot
        // config optimization.
        guard let config else {
            fatalError(.unexpected)
        }
        guard let remoteName = config.branchRemote(branch.name),
              let mergeName = config.branchMerge(branch.name)
        else { return nil }

        if remoteName == "." {
            return mergeName
        }
        else {
            guard let remote = remote(named: remoteName),
                  let refSpec = remote.refSpecs.first(where: { spec in
                      spec.direction == .fetch && spec.sourceMatches(refName: mergeName)
                  })
            else { return nil }

            return refSpec.transformToTarget(name: mergeName)?
                .droppingPrefix(String.remotePrefix)
        }
    }

    func setTrackingBranchName(of branch: Branch, to newValue: String?) {
        lock.lock()
        defer { lock.unlock() }
        var branchRef: OpaquePointer? = nil
        let result = git_reference_lookup(&branchRef, pointer, branch.longName)
        guard result == GIT_OK.rawValue else { return }
        git_branch_set_upstream(branchRef, newValue)
        config?.loadSnapshot()
    }

    /// Returns a branch object for this branch's remote tracking branch,
    /// or `nil` if no tracking branch is set or if it references a non-existent
    /// branch.
    func trackingBranch(of branch: Branch) -> Branch? {
        lock.lock()
        defer { lock.unlock() }
        var branchRef: OpaquePointer? = nil
        let result = git_reference_lookup(&branchRef, pointer, branch.longName)
        guard result == GIT_OK.rawValue else { return nil }
        guard let upstream = try? OpaquePointer.from({
            git_branch_upstream(&$0, branchRef)
        })
        else { return nil }
        return Branch(upstream, lock: lock)
    }
}
