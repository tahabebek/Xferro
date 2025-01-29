//
//  GitGraphTests.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import XCTest
@testable import Xferro

final class GitGraphTests: XCTestCase {

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

    func testGitGraph() throws {
        let repository = Fixtures.annoyRepository
        let settings = GGSettings(
            branchOrder: GGBranchOrder.longestFirst(isReverse: false),
            branches: try GGBranchSettings.from(GGBranchSettingsDef.gitFlow()),
            mergePatterns: GGMergePatterns.default
        )

        let graph = try GitGraph(
            repository: repository,
            settings: settings,
            maxCount: 100
        )
        XCTAssertEqual(graph.commits.count, 99)
    }
}
