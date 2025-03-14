//
//  InMemoryGitTests.swift
//  SwiftSpaceTests
//
//  Created by Taha Bebek on 1/7/25.
//

import XCTest
@testable import Xferro

final class GitTests: XCTestCase {

    override func setUp() {
        super.setUp()
        git_libgit2_init()
        Fixtures.sharedInstance.setUp()
    }

    override func tearDown() {
        git_libgit2_shutdown()
        Fixtures.sharedInstance.tearDown()
        super.tearDown()
    }

    func testInMemoryRepo() throws {
        let sourceRepo = Fixtures.simpleRepository
        let repo = try Repository(
            sourcePath: sourceRepo.workDir.path,
            shouldCopyFromSource: true,
            identity: .init(name: "test", email: "test@example.com")
        )

        XCTAssertNotNil(repo.pointer, "Repository should be initialized")

        var head: OpaquePointer?
        XCTAssertEqual(
            git_repository_head(&head, repo.pointer),
            0,
            "Should be able to get HEAD reference"
        )
        defer { git_reference_free(head) }

        // Verify we can read the commit
        let headOid = git_reference_target(head)
        var commit: OpaquePointer?
        XCTAssertEqual(
            git_commit_lookup(&commit, repo.pointer, headOid),
            0,
            "Should be able to look up HEAD commit"
        )
        defer { git_commit_free(commit) }

        // Verify the commit message
        let message = String(cString: git_commit_message(commit))
        XCTAssertEqual(message, "Merge branch 'alphabetize'\n", "Commit message should match")

        // Verify we can read the tree and its contents
        var tree: OpaquePointer?
        XCTAssertEqual(
            git_commit_tree(&tree, commit),
            0,
            "Should be able to get commit tree"
        )
        defer { git_tree_free(tree) }

        let entry = git_tree_entry_byname(tree, "README.md")
        XCTAssertNotNil(entry, "Test file should exist in tree")
    }
}
