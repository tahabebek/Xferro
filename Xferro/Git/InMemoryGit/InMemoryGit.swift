//
//  InMemoryGit.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 1/7/25.
//

import Foundation

class InMemoryGit {
    private(set) var repo: OpaquePointer?
    private(set) var refdbBackend: OpaquePointer?
    private var backend: UnsafeMutablePointer<git_odb_backend>?
    private var odb: OpaquePointer?

    init() throws {
        git_libgit2_init()

        if git_mempack_new(&backend) != 0 {
            throw GitError.initializationFailed("Failed to create mempack \(GitError.getLastErrorMessage())")
        }
        if git_odb_new(&odb) != 0 {
            throw GitError.initializationFailed("Failed to create ODB \(GitError.getLastErrorMessage())")
        }

        if git_odb_add_backend(odb, backend, 999) != 0 {
            throw GitError.initializationFailed("Failed to add backend \(GitError.getLastErrorMessage())")
        }

        if git_repository_wrap_odb(&repo, odb) != 0 {
            throw GitError.initializationFailed("Failed to create repository \(GitError.getLastErrorMessage())")
        }

        try setupRepositoryIndex()

        var refdb: OpaquePointer?
        if git_refdb_new(&refdb, repo) != 0 {
            throw GitError.initializationFailed("Failed to create refdb \(GitError.getLastErrorMessage())")
        }

        var backend: UnsafeMutablePointer<git_refdb_backend>?
        if create_memory_refdb(repo, &backend) != 0 {
            throw GitError.initializationFailed("Failed to create memory refdb backend \(GitError.getLastErrorMessage())")
        }

        if git_refdb_set_backend(refdb, backend) != 0 {
            throw GitError.initializationFailed("Failed to set refdb backend \(GitError.getLastErrorMessage())")
        }

        git_repository_set_refdb(repo, refdb)

        try setupRepositoryIdentity()
    }

    private func setupRepositoryIdentity() throws {
        var signature: UnsafeMutablePointer<git_signature>?
        let defaultResult = git_signature_default(&signature, repo)

        if defaultResult != 0 {
            if git_signature_new(&signature,
                                 "Memory Repo User",
                                 "memory-repo@example.com",
                                 Int64(Date().timeIntervalSince1970),
                                 0) != 0 {
                throw GitError.initializationFailed("Failed to create signature")
            }
        }

        if let sig = signature {
            git_signature_free(sig)
        }
    }

    private func setupRepositoryIndex() throws {
        var index: OpaquePointer?
        if git_index_new(&index) != 0 {
            throw GitError.initializationFailed("Failed to create index \(GitError.getLastErrorMessage())")
        }
        git_index_set_caps(index, GIT_INDEX_CAPABILITY_FROM_OWNER.rawValue)
        git_repository_set_index(repo, index)
        git_index_free(index)
    }

    deinit {
        git_odb_free(odb)
        git_repository_free(repo)
        git_libgit2_shutdown()
    }

    func copyFromRepository(sourcePath: String) throws {
        var sourceRepo: OpaquePointer?
        if git_repository_open(&sourceRepo, sourcePath) != 0 {
            throw GitError.initializationFailed("Failed to open source repository \(GitError.getLastErrorMessage())")
        }
        defer { git_repository_free(sourceRepo) }

        // Get the HEAD reference to find the latest commit
        var head: OpaquePointer?
        if git_repository_head(&head, sourceRepo) != 0 {
            throw GitError.mempackError("Failed to get HEAD reference \(GitError.getLastErrorMessage())")
        }
        defer { git_reference_free(head) }

        let headOid = git_reference_target(head)
        var sourceOdb: OpaquePointer?
        if git_repository_odb(&sourceOdb, sourceRepo) != 0 {
            throw GitError.mempackError("Failed to get source ODB \(GitError.getLastErrorMessage())")
        }
        defer { git_odb_free(sourceOdb) }

        var commit: OpaquePointer?
        if git_commit_lookup(&commit, sourceRepo, headOid) != 0 {
            throw GitError.mempackError("Failed to lookup HEAD commit \(GitError.getLastErrorMessage())")
        }
        defer { git_commit_free(commit) }

        try copyObject(oid: headOid!, from: sourceOdb)
        let treeOid = git_commit_tree_id(commit)
        try copyObject(oid: treeOid!, from: sourceOdb)
        try copyTreeContents(treeOid: treeOid!, sourceRepo: sourceRepo, sourceOdb: sourceOdb)

        let branchName = String(cString: git_reference_name(head))
        var newRef: OpaquePointer?

        // Force create/update the branch reference
        if git_reference_create(&newRef, repo, branchName, headOid, 1, nil) != 0 {
            throw GitError.mempackError("Failed to create branch \(GitError.getLastErrorMessage())")
        }
        git_reference_free(newRef)

        do {
            let fullBranchName = branchName.hasPrefix("refs/heads/") ? branchName : "refs/heads/\(branchName)"

            var branchRef: OpaquePointer?
            if git_reference_lookup(&branchRef, repo, fullBranchName) != 0 {
                throw GitError.mempackError("Branch \(fullBranchName) does not exist")
            }
            git_reference_free(branchRef)

            if git_reference_symbolic_create(&newRef, repo, "HEAD", fullBranchName, 1, nil) != 0 {
                throw GitError.mempackError("Failed to create HEAD reference \(GitError.getLastErrorMessage())")
            }
            git_reference_free(newRef)
        }
    }
    
    func createHEADReference(repo: OpaquePointer, branchName: String) throws {
        let fullBranchName = branchName.hasPrefix("refs/heads/") ? branchName : "refs/heads/\(branchName)"

        var branchRef: OpaquePointer?
        guard git_reference_lookup(&branchRef, repo, fullBranchName) == 0 else {
            throw GitError.mempackError("Branch \(fullBranchName) does not exist. \(GitError.getLastErrorMessage())")
        }
        defer { git_reference_free(branchRef) }

        var newRef: OpaquePointer?
        if git_reference_symbolic_create(&newRef, repo, "HEAD", fullBranchName, 1, nil) != 0 {
            throw GitError.mempackError("Failed to create HEAD reference: \(GitError.getLastErrorMessage())")
        }

        git_reference_free(newRef)
    }

    private func copyObject(oid: UnsafePointer<git_oid>, from sourceOdb: OpaquePointer?) throws {
        var obj: OpaquePointer?
        if git_odb_read(&obj, sourceOdb, oid) == 0 {
            defer { git_odb_object_free(obj) }

            var newOid = git_oid()

            let data = git_odb_object_data(obj)
            let size = git_odb_object_size(obj)
            let type = git_odb_object_type(obj)

            // Write to our ODB and get the new OID
            if git_odb_write(&newOid, self.odb, data, size, type) != 0 {
                throw GitError.mempackError("Failed to write object to database \(GitError.getLastErrorMessage())")
            }
        } else {
            throw GitError.mempackError("Failed to read object from source \(GitError.getLastErrorMessage())")
        }
    }

    // Helper function to recursively copy tree contents
    private func copyTreeContents(treeOid: UnsafePointer<git_oid>,
                                  sourceRepo: OpaquePointer?,
                                  sourceOdb: OpaquePointer?) throws {
        var tree: OpaquePointer?
        if git_tree_lookup(&tree, sourceRepo, treeOid) != 0 {
            throw GitError.mempackError("Failed to lookup tree \(GitError.getLastErrorMessage())")
        }
        defer { git_tree_free(tree) }

        let entryCount = git_tree_entrycount(tree)

        for i in 0..<entryCount {
            let entry = git_tree_entry_byindex(tree, i)
            let entryOid = git_tree_entry_id(entry)
            let entryType = git_tree_entry_type(entry)

            try copyObject(oid: entryOid!, from: sourceOdb)

            if entryType == GIT_OBJECT_TREE {
                try copyTreeContents(treeOid: entryOid!, sourceRepo: sourceRepo, sourceOdb: sourceOdb)
            }
        }
    }

    func createBranch(name: String, fromCommit commitSha: String) throws {
        guard let commit = try getCommit(sha: commitSha) else {
            throw GitError.mempackError("Commit not found \(GitError.getLastErrorMessage())")
        }
        var reference: OpaquePointer?
        if git_branch_create(&reference, repo, name, commit, 0) != 0 {
            throw GitError.mempackError("Failed to create branch \(GitError.getLastErrorMessage())")
        }
        git_reference_free(reference)
    }

    func getCommit(sha: String) throws -> OpaquePointer? {
        var oid = git_oid()
        if git_oid_fromstr(&oid, sha) != 0 {
            throw GitError.mempackError("Invalid SHA \(GitError.getLastErrorMessage())")
        }

        var commit: OpaquePointer?
        if git_commit_lookup(&commit, repo, &oid) != 0 {
            throw GitError.mempackError("Commit not found \(GitError.getLastErrorMessage())")
        }

        return commit
    }

    func getLatestCommit(branch: String) throws -> OpaquePointer? {
        var reference: OpaquePointer?
        if git_reference_lookup(&reference, repo, "refs/heads/\(branch)") != 0 {
            throw GitError.mempackError("Branch not found \(GitError.getLastErrorMessage())")
        }
        defer { git_reference_free(reference) }

        let oid = git_reference_target(reference)

        var commit: OpaquePointer?
        if git_commit_lookup(&commit, repo, oid) != 0 {
            throw GitError.mempackError("Commit not found \(GitError.getLastErrorMessage())")
        }

        return commit
    }

    func createCommit(message: String, parentCommitSha: String? = nil) throws -> String {
        var index: OpaquePointer?
        if git_repository_index(&index, repo) != 0 {
            throw GitError.mempackError("Failed to get index \(GitError.getLastErrorMessage())")
        }
        defer { git_index_free(index) }

        var treeId = git_oid()
        if git_index_write_tree(&treeId, index) != 0 {
            throw GitError.mempackError("Failed to write tree \(GitError.getLastErrorMessage())")
        }

        var tree: OpaquePointer?
        if git_tree_lookup(&tree, repo, &treeId) != 0 {
            throw GitError.mempackError("Failed to look up tree \(GitError.getLastErrorMessage())")
        }
        defer { git_tree_free(tree) }

        // Create signature for committer & author
        var signature: UnsafeMutablePointer<git_signature>?
        if git_signature_now(&signature, "Author Name", "author@email.com") != 0 {
            throw GitError.mempackError("Failed to create signature \(GitError.getLastErrorMessage())")
        }
        defer { git_signature_free(signature) }

        // Get parent commit if provided
        var parent: OpaquePointer?
        if let parentSha = parentCommitSha {
            parent = try getCommit(sha: parentSha)
        }
        defer { if parent != nil { git_commit_free(parent) } }

        var commitId = git_oid()
        let parentCount = parent != nil ? 1 : 0

        if git_commit_create(
            &commitId,
            repo,
            "HEAD",
            signature,
            signature,
            "UTF-8",
            message,
            tree,
            parentCount,
            &parent
        ) != 0 {
            throw GitError.mempackError("Failed to create commit \(GitError.getLastErrorMessage())")
        }

        var buffer = [Int8](repeating: 0, count: Int(GIT_OID_HEXSZ) + 1)
        git_oid_fmt(&buffer, &commitId)
        return String(cString: buffer)
    }

    func addFile(path: String, content: String) throws -> git_oid {
        var index: OpaquePointer?
        if git_repository_index(&index, repo) != 0 {
            throw GitError.mempackError("Failed to get index \(GitError.getLastErrorMessage())")
        }
        defer { git_index_free(index) }

        // Create blob from content
        var blobId = git_oid()
        guard let contentData = content.data(using: .utf8) else {
            throw GitError.mempackError("Failed to convert content to data")
        }

        if git_blob_create_from_buffer(&blobId, repo, [UInt8](contentData), contentData.count) != 0 {
            throw GitError.mempackError("Failed to create blob \(GitError.getLastErrorMessage())")
        }

        var entry = git_index_entry()
        entry.id = blobId
        entry.mode = UInt32(GIT_FILEMODE_BLOB.rawValue)
        entry.file_size = UInt32(contentData.count)

        let timestamp = time(nil)
        entry.ctime.seconds = Int32(git_time_t(timestamp))
        entry.mtime.seconds = Int32(git_time_t(timestamp))

        let pathStr = Array(path.utf8CString)
        pathStr.withUnsafeBufferPointer { ptr in
            entry.path = ptr.baseAddress
        }

        if git_index_add(index, &entry) != 0 {
            throw GitError.mempackError("Failed to add to index \(GitError.getLastErrorMessage())")
        }

        return blobId
    }
}

enum GitError: Error {
    static func getLastErrorMessage() -> String {
        let error = git_error_last()
        let errorMessage = error?.pointee.message.map { String(cString: $0) } ?? "Unknown error"
        return errorMessage
    }
    case initializationFailed(String)
    case cloneFailed(String)
    case mempackError(String)
    case writeFailed(String)
    case readFailed(String)
}
