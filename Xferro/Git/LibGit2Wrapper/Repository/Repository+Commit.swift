//
//  Repository+Commit.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension Repository {
    @discardableResult
    func createEmptyCommit() -> Commit {
        lock.lock()
        defer { lock.unlock() }
        let commit: Commit = commit(message: "Initial Commit").mustSucceed(gitDir)
        return commit
    }

    func commit(
        tree: OpaquePointer, // git_tree
        parentCommits: [OpaquePointer?], // [git_commit]
        message: String,
        signature: UnsafeMutablePointer<git_signature>? = nil,
        updatingRef refName: String = "HEAD"
    ) -> Result<git_oid, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var msgBuf = git_buf()
        git_message_prettify(&msgBuf, message, 0, /* ascii for # */ 35)
        defer { git_buf_dispose(&msgBuf) }

        let parentsContiguous = ContiguousArray(parentCommits)
        let result: Result<git_oid, NSError> = parentsContiguous.withUnsafeBufferPointer { unsafeBuffer in
            var commitOID = git_oid()
            let parentsPtr = UnsafeMutablePointer(mutating: unsafeBuffer.baseAddress)
            let result = git_commit_create(
                &commitOID,
                self.pointer,
                refName,
                signature,
                signature,
                "UTF-8",
                msgBuf.ptr,
                tree,
                parentCommits.count,
                parentsPtr
            )
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_commit_create"))
            }
            return .success(commitOID)
        }
        return result
    }

    func commit(
        oid: git_oid,
        parentCommits: [OpaquePointer?], // [git_commit]
        message: String,
        signature: UnsafeMutablePointer<git_signature>? = nil
    ) -> Result<git_oid, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var tree: OpaquePointer? = nil
        var treeOIDCopy = oid
        let lookupResult = git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
        guard lookupResult == GIT_OK.rawValue else {
            let err = NSError(gitError: lookupResult, pointOfFailure: "git_tree_lookup")
            return .failure(err)
        }
        defer { git_tree_free(tree) }
        let commit = commit(tree: tree!, parentCommits: parentCommits, message: message, signature: signature)
        return commit
    }

    func commit(
        index: OpaquePointer, // git_index
        parentCommits: [OpaquePointer?], // [git_commit]
        message: String,
        signature: UnsafeMutablePointer<git_signature>? = nil
    ) -> Result<git_oid, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var treeOID = git_oid()
        let result = git_index_write_tree(&treeOID, index)
        guard result == GIT_OK.rawValue else {
            let err = NSError(gitError: result, pointOfFailure: "git_index_write_tree")
            return .failure(err)
        }
        let commit = commit(oid: treeOID, parentCommits: parentCommits, message: message, signature: signature)
        return commit
    }

    func commit(
        message: String,
        signature: UnsafeMutablePointer<git_signature>? = nil
    ) -> Result<git_oid, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let unborn: Bool
        let result = git_repository_head_unborn(self.pointer)
        if result == 1 {
            unborn = true
        } else if result == 0 {
            unborn = false
        } else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_head_unborn"))
        }

        var commit: OpaquePointer? = nil
        defer { git_commit_free(commit) }
        if !unborn {
            var head: OpaquePointer? = nil
            defer { git_reference_free(head) }
            var result = git_repository_head(&head, self.pointer)
            guard result == GIT_OK.rawValue else {
                return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
            }

            // get head oid
            var oid = git_reference_target(head).pointee

            // get head commit
            result = git_commit_lookup(&commit, self.pointer, &oid)
            guard result == GIT_OK.rawValue else {
                return Result.failure(NSError(gitError: result, pointOfFailure: "git_commit_lookup"))
            }
        }
        let oid = unsafeIndex().flatMap { index in
            defer { git_index_free(index) }
            return self.commit(index: index, parentCommits: [commit].filter { $0 != nil }, message: message, signature: signature)
        }
        return oid
    }

    // MARK: - function

    /// Loads the commit from the HEAD.
    ///
    /// Returns the HEAD commit, or an error.
    func commit() -> Result<Commit, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let headOID = Head.of(self).oid
        return commit(headOID)
    }

    /// Loads the commit with the given OID.
    ///
    /// oid - The OID of the commit to look up.
    ///
    /// Returns the commit if it exists, or an error.
    func commit(_ oid: OID) -> Result<Commit, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let commit = withGitObject(oid, type: GIT_OBJECT_COMMIT) { Commit($0, lock: lock) }
        return commit
    }

    /// Load all commits in the specified branch in topological & time order descending
    ///
    /// :param: branch The branch to get all commits from
    /// :returns: Returns a result with array of branches or the error that occurred
    func commits(in branch: Branch, reversed: Bool = false) -> CommitIterator {
        lock.lock()
        defer { lock.unlock() }
        let iterator = CommitIterator(repo: self, root: branch.oid.oid, reversed: reversed)
        return iterator
    }

    func commits(in tag: TagReference) -> CommitIterator {
        lock.lock()
        defer { lock.unlock() }
        let iterator = CommitIterator(repo: self, root: tag.oid.oid)
        return iterator
    }

    /// Perform a commit with arbitrary numbers of parent commits.
    func commit(tree treeOID: OID,
                parents: [Commit],
                message: String,
                signature: Signature? = nil,
                updatingRef refName: String = "HEAD"
    ) -> Result<Commit, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let sign: Signature
        do {
            sign = try signature ?? Signature.default(self).get()
        } catch {
            return .failure(error as NSError)
        }
        let result: Result<Commit, NSError> = sign.makeUnsafeSignature().flatMap { signature in
            defer { git_signature_free(signature) }
            var tree: OpaquePointer? = nil
            var treeOIDCopy = treeOID.oid
            let lookupResult = git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
            guard lookupResult == GIT_OK.rawValue else {
                let err = NSError(gitError: lookupResult, pointOfFailure: "git_tree_lookup")
                return .failure(err)
            }
            defer { git_tree_free(tree) }

            // libgit2 expects a C-like array of parent git_commit pointer
            var parentGitCommits: [OpaquePointer?] = []
            defer {
                for commit in parentGitCommits {
                    git_commit_free(commit)
                }
            }
            for parentCommit in parents {
                var parent: OpaquePointer? = nil
                var oid = parentCommit.oid.oid
                let lookupResult = git_commit_lookup(&parent, self.pointer, &oid)
                guard lookupResult == GIT_OK.rawValue else {
                    let err = NSError(gitError: lookupResult, pointOfFailure: "git_commit_lookup")
                    return .failure(err)
                }
                parentGitCommits.append(parent!)
            }

            return commit(
                tree: tree!,
                parentCommits: parentGitCommits,
                message: message,
                signature: signature,
                updatingRef: refName
            ).flatMap { commit(OID($0)) }
        }
        return result
    }

    /// Perform a commit of the staged files with the specified message and signature,
    /// assuming we are not doing a merge and using the current tip as the parent.
    func commit(message: String, signature: Signature? = nil) -> Result<Commit, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let sign: Signature
        do {
            sign = try signature ?? Signature.default(self).get()
        } catch {
            return .failure(error as NSError)
        }
        let result: Result<Commit, NSError> = sign.makeUnsafeSignature().flatMap {
            self.commit(message: message, signature: $0).flatMap {
                commit(OID($0))
            }
        }
        return result
    }

    func isDescendant(of oid: OID, for base: OID) -> Result<Bool, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var oid1 = oid.oid
        var oid2 = base.oid
        let result = git_graph_descendant_of(self.pointer, &oid1, &oid2)
        switch result {
        case 0:
            return .success(false)
        case 1:
            return .success(true)
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_graph_descendant_of"))
        }
    }

    func isDescendant(of oid: OID) -> Result<Bool, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let headOID = Head.of(self).oid
        return self.isDescendant(of: oid, for: headOID)
    }
}
