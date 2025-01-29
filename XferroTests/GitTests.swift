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
            sourcePath: sourceRepo.workDir!.path,
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

    func testDumpRepo() throws {
        RepoManager().printCommitTree(Fixtures.annoyRepository)
    }

    func testLocalBranchMap() throws {
        let simpleRepo = Fixtures.simpleRepository
        let localBranchMap = simpleRepo.localBranchGraph()
        XCTAssertTrue(localBranchMap.isSuccess)
    }

    func testGitLogParse() {
        let output = """
            \n* 31de9d1 initial revision\n* 4756bae (upstream/master, upstream/HEAD, origin/master, master) Merge branch \'main\' of https://github.com/spotify/annoy\n* 1f53a76 (HEAD -> pre-commit-hook-for-leaks) add pre-commit hook to scan leaks\n* 2375724 Initial commit\n|/  \n| * f6e0f65 (ai/xAI) WIP\n|/  \n| * 4d410c0 (ai/togetherai) added text embeddings request handling conformance\n|/  \n| * e61c99d (ai/ENG-1618-Photo-Editor) removed print statements from debugging\n|/  \n* | 7603d7c (ai/ENG-1490) Merge branch \'main\' of https://github.com/PreternaturalAI/AI into ENG-1490\n|/|   \n| |/  \n| | * 9339454 (ai/ENG-1721) Update package\n| |/  \n| | * db3f200 (ai/linter) Ran linter against _Gemini and _Gemini Tests\n| * 4801fe5 (ai/PlayHT-Updates) update\n* 5f90137 (ai/ENG-1700) Merge branch \'main\' of https://github.com/PreternaturalAI/AI into ENG-1700\n|/  \n| * 5b3e136 (ai/ENG-1846) Fix\n* 44eedb2 (ai/main) Merge pull request #56 from PreternaturalAI/aksh1t/ENG-1898
        """

        var branchLanes: [String] = []
        
    }
}
