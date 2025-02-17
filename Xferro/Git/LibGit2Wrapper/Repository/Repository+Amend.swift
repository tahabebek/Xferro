//
//  Repository+Amend.swift
//  Xferro
//
//  Created by Taha Bebek on 2/17/25.
//

import Foundation

extension Repository {
    @discardableResult
    func amend(message: String? = nil) -> Result<git_oid, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let headCommit = commit().mustSucceed()
        var commit: OpaquePointer? = nil
        var oid = headCommit.oid.oid
        var result = git_commit_lookup(&commit, self.pointer, &oid)
        guard result == GIT_OK.rawValue else {
            let err = NSError(gitError: result, pointOfFailure: "git_commit_lookup")
            return .failure(err)
        }

        var index: OpaquePointer?
        result = git_repository_index(&index, self.pointer)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
        }
        defer { git_index_free(index) }

        var treeOID = git_oid()
        result = git_index_write_tree(&treeOID, index)
        guard result == GIT_OK.rawValue else {
            let err = NSError(gitError: result, pointOfFailure: "git_index_write_tree")
            return .failure(err)
        }
        var tree: OpaquePointer? = nil
        var treeOIDCopy = treeOID
        result = git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
        guard result == GIT_OK.rawValue else {
            let err = NSError(gitError: result, pointOfFailure: "git_tree_lookup")
            return .failure(err)
        }
        defer { git_tree_free(tree) }

        var messageBuff: UnsafeMutablePointer<CChar>? = nil
        if let message {
            var msgBuf = git_buf()
            git_message_prettify(&msgBuf, message, 0, /* ascii for # */ 35)
            defer { git_buf_dispose(&msgBuf) }
            messageBuff = msgBuf.ptr
        }

        var commitOID = git_oid()
        result = git_commit_amend(
            &commitOID,
            commit,
            "HEAD",
            nil,
            nil,
            "UTF-8",
            messageBuff,
            tree
        )
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_commit_create"))
        }
        return .success(commitOID)
    }
}
