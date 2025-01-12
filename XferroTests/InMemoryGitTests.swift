//
//  InMemoryGitTests.swift
//  SwiftSpaceTests
//
//  Created by Taha Bebek on 1/7/25.
//

import XCTest
@testable import Xferro

final class InMemoryGitTests: XCTestCase {
    var testRepoPath: String!
    var sourceRepo: OpaquePointer?

    override func setUp() {
        super.setUp()

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        testRepoPath = tempDir.path

        git_libgit2_init()
        var repo: OpaquePointer?
        guard git_repository_init(&repo, testRepoPath, 0) == 0 else {
            XCTFail("Failed to initialize test repository \(GitError.getLastErrorMessage())")
            return
        }
        sourceRepo = repo
        do {
            try createTestContent()
        } catch {
            XCTFail("Failed to create test content: \(error.localizedDescription)")
        }
    }

    override func tearDown() {
        if let repo = sourceRepo {
            git_repository_free(repo)
        }

        try? FileManager.default.removeItem(atPath: testRepoPath)

        super.tearDown()
    }

    func testInitialization() throws {
        let repo = try InMemoryGit()
        XCTAssertNotNil(repo.repo, "Repository should be initialized")

        // Try writing a blob to verify backend works
        var oid = git_oid()
        let data = "test content"
        if git_blob_create_frombuffer(&oid, repo.repo, data, data.count) != 0 {
            throw GitError.writeFailed(GitError.getLastErrorMessage())
        }

        // Try reading it back
        var blob: OpaquePointer?
        if git_blob_lookup(&blob, repo.repo, &oid) != 0 {
            throw GitError.readFailed("")
        }

        // Verify content
        let content = String(cString: git_blob_rawcontent(blob).assumingMemoryBound(to: CChar.self))
        XCTAssertEqual(content, "test content")

        git_blob_free(blob)
    }

    func testCopyFromRepository() throws {
        let memoryRepo = try InMemoryGit()
        try memoryRepo.copyFromRepository(sourcePath: testRepoPath)

        var head: OpaquePointer?
        XCTAssertEqual(
            git_repository_head(&head, memoryRepo.repo),
            0,
            "Should be able to get HEAD reference"
        )
        defer { git_reference_free(head) }

        // Verify we can read the commit
        let headOid = git_reference_target(head)
        var commit: OpaquePointer?
        XCTAssertEqual(
            git_commit_lookup(&commit, memoryRepo.repo, headOid),
            0,
            "Should be able to look up HEAD commit"
        )
        defer { git_commit_free(commit) }

        // Verify the commit message
        let message = String(cString: git_commit_message(commit))
        XCTAssertEqual(message, "Initial commit", "Commit message should match")

        // Verify we can read the tree and its contents
        var tree: OpaquePointer?
        XCTAssertEqual(
            git_commit_tree(&tree, commit),
            0,
            "Should be able to get commit tree"
        )
        defer { git_tree_free(tree) }

        let entry = git_tree_entry_byname(tree, "test.txt")
        XCTAssertNotNil(entry, "Test file should exist in tree")
    }

    func testCreateBranch() throws {
        let memoryRepo = try InMemoryGit()
        try memoryRepo.copyFromRepository(sourcePath: testRepoPath)

        var head: OpaquePointer?
        XCTAssertEqual(git_repository_head(&head, sourceRepo), 0)
        defer { git_reference_free(head) }

        let headOid = git_reference_target(head)
        var buffer = [Int8](repeating: 0, count: Int(GIT_OID_HEXSZ) + 1)
        git_oid_fmt(&buffer, headOid)
        let commitSha = String(cString: buffer)

        try memoryRepo.createBranch(name: "a-branch", fromCommit: commitSha)

        var branchRef: OpaquePointer?
        XCTAssertEqual(
            git_reference_lookup(&branchRef, memoryRepo.repo, "refs/heads/a-branch"),
            0,
            "Branch should exist"
        )
        defer { git_reference_free(branchRef) }

        let branchOid = git_reference_target(branchRef)
        XCTAssertEqual(git_oid_cmp(headOid, branchOid), 0, "Branch should point to HEAD commit")
    }

    func testGetCommit() throws {
        let memoryRepo = try InMemoryGit()
        try memoryRepo.copyFromRepository(sourcePath: testRepoPath)

        // Get HEAD commit SHA
        var head: OpaquePointer?
        XCTAssertEqual(git_repository_head(&head, sourceRepo), 0)
        defer { git_reference_free(head) }

        let headOid = git_reference_target(head)
        var buffer = [Int8](repeating: 0, count: Int(GIT_OID_HEXSZ) + 1)
        git_oid_fmt(&buffer, headOid)
        let commitSha = String(cString: buffer)

        // Test getting commit
        let commit = try memoryRepo.getCommit(sha: commitSha)
        XCTAssertNotNil(commit, "Should get commit")
        defer { git_commit_free(commit) }

        // Verify commit message
        let message = String(cString: git_commit_message(commit))
        XCTAssertEqual(message, "Initial commit")
    }

    func testAddFile() throws {
        let memoryRepo = try InMemoryGit()
        try memoryRepo.copyFromRepository(sourcePath: testRepoPath)

        let testPath = "test-file.txt"
        let testContent = "Hello, this is test content!"

        var blobId = try memoryRepo.addFile(path: testPath, content: testContent)

        // Verify the blob content directly
        var blob: OpaquePointer?
        XCTAssertEqual(
            git_blob_lookup(&blob, memoryRepo.repo, &blobId),
            0,
            "Should find blob in repository"
        )
        defer { git_blob_free(blob) }

        let content = String(cString: git_blob_rawcontent(blob).assumingMemoryBound(to: CChar.self))
        XCTAssertEqual(content, testContent, "Blob content should match input")
    }

    func testCreateCommit() throws {
        let memoryRepo = try InMemoryGit()
        try memoryRepo.copyFromRepository(sourcePath: testRepoPath)

        // Get current HEAD commit
        var head: OpaquePointer?
        XCTAssertEqual(git_repository_head(&head, memoryRepo.repo), 0)
        defer { git_reference_free(head) }

        let headOid = git_reference_target(head)
        var buffer = [Int8](repeating: 0, count: Int(GIT_OID_HEXSZ) + 1)
        git_oid_fmt(&buffer, headOid)
        let parentCommitSha = String(cString: buffer)

        let filePath = "new-file.txt"
        let fileContent = "This is a new file"
        let commitMessage = "Add new file"

        let _ = try memoryRepo.addFile(path: filePath, content: fileContent)
        let commitSha = try memoryRepo.createCommit(message: commitMessage, parentCommitSha: parentCommitSha)

        // Verify commit
        guard let commit = try memoryRepo.getCommit(sha: commitSha) else {
            XCTFail("Should find commit")
            return
        }
        defer { git_commit_free(commit) }

        let message = String(cString: git_commit_message(commit))
        XCTAssertEqual(message, commitMessage)

        // Verify file in commit tree
        var tree: OpaquePointer?
        XCTAssertEqual(git_commit_tree(&tree, commit), 0)
        defer { git_tree_free(tree) }

        var entry: OpaquePointer?
        XCTAssertEqual(git_tree_entry_bypath(&entry, tree, filePath), 0, "Should find file in tree")
        git_tree_entry_free(entry)
    }

    func testGetLatestCommitWithMultipleCommits() throws {
        let memoryRepo = try InMemoryGit()
        try memoryRepo.copyFromRepository(sourcePath: testRepoPath)

        // Get initial HEAD commit SHA
        var head: OpaquePointer?
        XCTAssertEqual(git_repository_head(&head, memoryRepo.repo), 0)
        defer { git_reference_free(head) }

        let headOid = git_reference_target(head)
        var buffer = [Int8](repeating: 0, count: Int(GIT_OID_HEXSZ) + 1)
        git_oid_fmt(&buffer, headOid)
        let initialCommitSha = String(cString: buffer)

        // Add first file and commit
        let _ = try memoryRepo.addFile(path: "first-file.txt", content: "First file content")
        let firstCommitSha = try memoryRepo.createCommit(
            message: "First additional commit",
            parentCommitSha: initialCommitSha
        )

        // Add second file and commit
        let _ = try memoryRepo.addFile(path: "second-file.txt", content: "Second file content")
        let secondCommitSha = try memoryRepo.createCommit(
            message: "Second additional commit",
            parentCommitSha: firstCommitSha
        )

        // Get latest commit
        let latestCommit = try memoryRepo.getLatestCommit(branch: "master")
        XCTAssertNotNil(latestCommit)
        defer { git_commit_free(latestCommit) }

        // Verify latest commit message
        let message = String(cString: git_commit_message(latestCommit))
        XCTAssertEqual(message, "Second additional commit")

        // Verify latest commit SHA matches second commit
        var latestBuffer = [Int8](repeating: 0, count: Int(GIT_OID_HEXSZ) + 1)
        git_oid_fmt(&latestBuffer, git_commit_id(latestCommit))
        let latestCommitSha = String(cString: latestBuffer)
        XCTAssertEqual(latestCommitSha, secondCommitSha)
    }

    private func createTestContent() throws {
        // Create a test file
        let testFilePath = (testRepoPath as NSString).appendingPathComponent("test.txt")
        let testContent = "Hello, this is a test file!"
        try testContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        // Create a Git index for staging files
        var index: OpaquePointer?
        guard git_repository_index(&index, sourceRepo) == 0 else {
            throw GitError.initializationFailed("Failed to get repository index")
        }
        defer { git_index_free(index) }

        // Add our test file to the index
        guard git_index_add_bypath(index, "test.txt") == 0 else {
            throw GitError.initializationFailed("Failed to add file to index")
        }

        // Write the index to disk
        guard git_index_write(index) == 0 else {
            throw GitError.initializationFailed("Failed to write index")
        }

        try createInitialCommit()
    }

    private func createInitialCommit() throws {
        var index: OpaquePointer?
        guard git_repository_index(&index, sourceRepo) == 0 else {
            throw GitError.initializationFailed("Failed to get repository index")
        }
        defer { git_index_free(index) }

        // Get the tree from the index
        var treeId = git_oid()
        guard git_index_write_tree(&treeId, index) == 0 else {
            throw GitError.initializationFailed("Failed to write tree")
        }

        var tree: OpaquePointer?
        guard git_tree_lookup(&tree, sourceRepo, &treeId) == 0 else {
            throw GitError.initializationFailed("Failed to lookup tree")
        }
        defer { git_tree_free(tree) }

        // Create the commit
        var commitId = git_oid()
        var signature: UnsafeMutablePointer<git_signature>?
        git_signature_new(&signature, "Test Author", "test@example.com", 123456789, 0)
        defer { git_signature_free(signature) }

        guard git_commit_create(
            &commitId,
            sourceRepo,
            "HEAD",
            signature,
            signature,
            "UTF-8",
            "Initial commit",
            tree,
            0,
            nil
        ) == 0 else {
            throw GitError.initializationFailed("Failed to create commit")
        }
    }
}
