//
//  Repository+Memory.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import Foundation

extension Repository {
    convenience init(
        sourcePath: String,
        shouldCopyFromSource: Bool = true,
        identity: CommitIdentity = .init(name: "Author", email: "author@example.com")
    ) throws {
        var odb: OpaquePointer?
        var odbBackend: UnsafeMutablePointer<git_odb_backend>?

        if git_mempack_new(&odbBackend) != 0 {
            throw GitError.initializationFailed("Failed to create mempack \(GitError.getLastErrorMessage())")
        }
        if git_odb_new(&odb) != 0 {
            throw GitError.initializationFailed("Failed to create ODB \(GitError.getLastErrorMessage())")
        }

        if git_odb_add_backend(odb, odbBackend, 999) != 0 {
            throw GitError.initializationFailed("Failed to add backend \(GitError.getLastErrorMessage())")
        }

        var repo: OpaquePointer?

        if git_repository_wrap_odb(&repo, odb) != 0 {
            throw GitError.initializationFailed("Failed to create repository \(GitError.getLastErrorMessage())")
        }

        guard let repo else {
            fatalError("repo is nil")
        }
        self.init(repo)
        try setupRepositoryIndex()

        var refdb: OpaquePointer?
        if git_refdb_new(&refdb, repo) != 0 {
            throw GitError.initializationFailed("Failed to create refdb \(GitError.getLastErrorMessage())")
        }

        var refdbBackend: UnsafeMutablePointer<git_refdb_backend>?
        if create_memory_refdb(repo, &refdbBackend) != 0 {
            throw GitError.initializationFailed("Failed to create memory refdb backend \(GitError.getLastErrorMessage())")
        }

        if git_refdb_set_backend(refdb, refdbBackend) != 0 {
            throw GitError.initializationFailed("Failed to set refdb backend \(GitError.getLastErrorMessage())")
        }

        git_repository_set_refdb(repo, refdb)
        try setupRepositoryIdentity(sourcePath: sourcePath, identity: identity)
        if shouldCopyFromSource {
            try copyFromRepository(sourcePath: sourcePath, targetOdb: odb)
        }
    }

    private func setupRepositoryIdentity(sourcePath: String, identity: CommitIdentity) throws {
        let configPath = String(sourcePath.replacingOccurrences(of: "/", with: "-").appending("-config").dropFirst())
        let addConfigResult = addConfig(path: FileManager.default.temporaryDirectory.appendingPathComponent(configPath).path, level: .repository)
        switch addConfigResult {
        case .success:
            let nameResult = config.set(string: identity.name, for: "user.name")
            if case .failure(let error) = nameResult {
                fatalError(error.localizedDescription)
            }
            let emailResult = config.set(string: identity.email, for: "user.email")
            if case .failure(let error) = emailResult {
                fatalError(error.localizedDescription)
            }
        case .failure(let failure):
            fatalError(failure.localizedDescription)
        }
    }


    private func setupRepositoryIndex() throws {
        var index: OpaquePointer?
        if git_index_new(&index) != 0 {
            throw GitError.initializationFailed("Failed to create index \(GitError.getLastErrorMessage())")
        }
        git_index_set_caps(index, GIT_INDEX_CAPABILITY_FROM_OWNER.rawValue)
        git_repository_set_index(pointer, index)
        git_index_free(index)
    }

    private func copyFromRepository(sourcePath: String, targetOdb: OpaquePointer?) throws {
        let stringsResult = config.all()
        switch stringsResult {
        case .success(let strings):
            print("strings: \(strings)")
            for (key, string) in strings {
                print("key: \(key), string: \(string)")
            }
        case .failure(let error):
            print(error.localizedDescription)
        }

        let referencesResult = references(withPrefix: "")
        switch referencesResult {
        case .success(let references):
            for reference in references {
                print("reference: \(reference)")
            }
        case .failure(let error):
            print(error.localizedDescription)
        }

        var sourceRepo: OpaquePointer?
        if git_repository_open(&sourceRepo, sourcePath) != 0 {
            throw GitError.initializationFailed("Failed to open source repository \(GitError.getLastErrorMessage())")
        }
        defer { git_repository_free(sourceRepo) }

        // Get the HEAD reference to find the latest commit
        var head: OpaquePointer?
        let result = git_repository_head(&head, sourceRepo)

        switch result {
        case 0:
            // Success - HEAD was retrieved correctly
            print("success")

        case -9:
            // Repository exists but HEAD doesn't point to a valid commit yet
            throw GitError.mempackError("Repository HEAD is in an invalid state - no commits exist yet")

        case -3:
            // HEAD reference is missing
            throw GitError.mempackError("HEAD reference not found - repository might be corrupt")

        default:
            // Other errors including permission issues
            print(GitError.getLastErrorMessage())
            throw GitError.mempackError("Failed to get HEAD reference: \(GitError.getLastErrorMessage())")
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

        try copyObject(oid: headOid!, from: sourceOdb, to: targetOdb)
        let treeOid = git_commit_tree_id(commit)
        try copyObject(oid: treeOid!, from: sourceOdb, to: targetOdb)
        try copyTreeContents(treeOid: treeOid!, sourceRepo: sourceRepo, sourceOdb: sourceOdb, targetOdb: targetOdb)

        let branchName = String(cString: git_reference_name(head))
        var newRef: OpaquePointer?

        // Force create/update the branch reference
        if git_reference_create(&newRef, pointer, branchName, headOid, 1, nil) != 0 {
            throw GitError.mempackError("Failed to create branch \(GitError.getLastErrorMessage())")
        }
        git_reference_free(newRef)

        do {
            let fullBranchName = branchName.hasPrefix("refs/heads/") ? branchName : "refs/heads/\(branchName)"

            var branchRef: OpaquePointer?
            if git_reference_lookup(&branchRef, pointer, fullBranchName) != 0 {
                throw GitError.mempackError("Branch \(fullBranchName) does not exist")
            }
            git_reference_free(branchRef)

            if git_reference_symbolic_create(&newRef, pointer, "HEAD", fullBranchName, 1, nil) != 0 {
                throw GitError.mempackError("Failed to create HEAD reference \(GitError.getLastErrorMessage())")
            }
            git_reference_free(newRef)
        }
    }
    
    private func copyObject(oid: UnsafePointer<git_oid>, from sourceOdb: OpaquePointer?, to targetOdb: OpaquePointer?) throws {
        var obj: OpaquePointer?
        if git_odb_read(&obj, sourceOdb, oid) == 0 {
            defer { git_odb_object_free(obj) }

            var newOid = git_oid()

            let data = git_odb_object_data(obj)
            let size = git_odb_object_size(obj)
            let type = git_odb_object_type(obj)

            // Write to our ODB and get the new OID
            if git_odb_write(&newOid, targetOdb, data, size, type) != 0 {
                throw GitError.mempackError("Failed to write object to database \(GitError.getLastErrorMessage())")
            }
        } else {
            throw GitError.mempackError("Failed to read object from source \(GitError.getLastErrorMessage())")
        }
    }

    // Helper function to recursively copy tree contents
    private func copyTreeContents(
        treeOid: UnsafePointer<git_oid>,
        sourceRepo: OpaquePointer?,
        sourceOdb: OpaquePointer?,
        targetOdb: OpaquePointer?
    ) throws {
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

            try copyObject(oid: entryOid!, from: sourceOdb, to: targetOdb)

            if entryType == GIT_OBJECT_TREE {
                try copyTreeContents(treeOid: entryOid!, sourceRepo: sourceRepo, sourceOdb: sourceOdb, targetOdb: targetOdb)
            }
        }
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
