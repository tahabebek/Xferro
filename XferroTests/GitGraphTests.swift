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
            includeRemote: false,
            branches: try GGBranchSettings.from(GGBranchSettingsDef.gitFlow()),
            mergePatterns: GGMergePatterns.default
        )

        let graph = try GitGraph(
            repository: repository,
            settings: settings,
            maxCount: 20
        )

        DataManager.save(graph, filename: "annoy_graph.json")

        XCTAssertEqual(graph.commits.count, 19)
        XCTAssertEqual(graph.allBranches.count, 9)

        typealias ExpectedCommitData = (
            shortOid: String,
            isMerged: Bool,
            parentOIDs: [String],
            childrenOIDs: [String],
            branches: [Int],
            tags: [Int],
            branchTrace: Int
        )
        let expectedCommitData: [ExpectedCommitData]  = [
            (shortOid: "4021a8f", isMerged: false, parentOIDs: ["2b1f499"], childrenOIDs: ["acd1d0f"], branches: [0,4,7], tags: [8], branchTrace: 0), //0
            (shortOid: "2b1f499", isMerged: false, parentOIDs: ["44eedb2"], childrenOIDs: ["4021a8f"], branches: [], tags: [], branchTrace: 0), //1
            (shortOid: "e28c30f", isMerged: true, parentOIDs: ["96c7895", "44eedb2"], childrenOIDs: [], branches: [6], tags: [], branchTrace: 6), //2
            (shortOid: "96c7895", isMerged: false, parentOIDs: ["6fac42d"], childrenOIDs: ["e28c30f"], branches: [], tags: [], branchTrace: 6), //3
            (shortOid: "6fac42d", isMerged: false, parentOIDs: ["68b739d"], childrenOIDs: ["96c7895"], branches: [], tags: [], branchTrace: 6), //4
            (shortOid: "68b739d", isMerged: true, parentOIDs: ["3fe5468", "1f99056"], childrenOIDs: ["6fac42d"], branches: [], tags: [], branchTrace: 6), //5
            (shortOid: "3fe5468", isMerged: false, parentOIDs: ["5b3e136"], childrenOIDs: ["68b739d"], branches: [], tags: [], branchTrace: 6), //6
            (shortOid: "1f99056", isMerged: false, parentOIDs: ["5b3e136"], childrenOIDs: ["68b739d"], branches: [], tags: [], branchTrace: 1), //7
            (shortOid: "44eedb2", isMerged: true, parentOIDs: ["32ed3e6", "354ab4a"], childrenOIDs: ["2b1f499", "e28c30f"], branches: [5], tags: [], branchTrace: 0), //8
            (shortOid: "354ab4a", isMerged: false, parentOIDs: ["32ed3e6"], childrenOIDs: ["44eedb2"], branches: [], tags: [], branchTrace: 2), //9
            (shortOid: "5b3e136", isMerged: false, parentOIDs: ["3aba2ad"], childrenOIDs: ["3fe5468", "1f99056"], branches: [], tags: [], branchTrace: 1), //10
            (shortOid: "3aba2ad", isMerged: false, parentOIDs: ["68d193a"], childrenOIDs: ["5b3e136"], branches: [], tags: [], branchTrace: 1), //11
            (shortOid: "68d193a", isMerged: true, parentOIDs: ["f2f807c", "114db0b"], childrenOIDs: ["3aba2ad"], branches: [], tags: [], branchTrace: 1), //12
            (shortOid: "f2f807c", isMerged: false, parentOIDs: ["fbc2f10"], childrenOIDs: ["68d193a"], branches: [], tags: [], branchTrace: 1), //13
            (shortOid: "114db0b", isMerged: false, parentOIDs: ["f74b0f5"], childrenOIDs: ["68d193a"], branches: [], tags: [], branchTrace: 3), //14
            (shortOid: "f74b0f5", isMerged: false, parentOIDs: ["fbc2f10"], childrenOIDs: ["114db0b"], branches: [], tags: [], branchTrace: 3), //15
            (shortOid: "fbc2f10", isMerged: false, parentOIDs: ["f4ab306"], childrenOIDs: ["f2f807c", "f74b0f5"], branches: [], tags: [], branchTrace: 1), //16
            (shortOid: "f4ab306", isMerged: true, parentOIDs: ["78c6949", "32ed3e6"], childrenOIDs: ["fbc2f10"], branches: [], tags: [], branchTrace: 1), //17
            (shortOid: "32ed3e6", isMerged: true, parentOIDs: ["074e4d0", "5f90137"], childrenOIDs: ["44eedb2", "354ab4a", "f4ab306"], branches: [], tags: [], branchTrace: 0), //18
        ]

        for (index, commit) in graph.commits.enumerated() {
            XCTAssertEqual(commit.shortOID, expectedCommitData[index].shortOid)
            XCTAssertEqual(commit.isMerge, expectedCommitData[index].isMerged)
            XCTAssertEqual(commit.debugParentOIDs, expectedCommitData[index].parentOIDs)
            XCTAssertEqual(commit.debugchildrenOIDs, expectedCommitData[index].childrenOIDs)
            XCTAssertEqual(commit.branches, expectedCommitData[index].branches)
            XCTAssertEqual(commit.tags, expectedCommitData[index].tags)
            XCTAssertEqual(commit.branchTrace, expectedCommitData[index].branchTrace)
        }

        XCTAssertEqual(graph.branches, [0, 4, 5, 6, 7])
        XCTAssertEqual(graph.tags, [8])
        XCTAssertEqual(graph.head.name, "git-graph-tests")
        XCTAssertEqual(graph.head.isBranch, true)
        XCTAssertEqual(graph.head.oid.debugOID, "4021a8f")

        let expectedBranches: [GGBranchInfo] = [
            .init(target: OID(string: "4021a8f960476cebf51f5daf31483fd9d6f0452a")!, mergeTarget: nil, sourceBranch: 2, targetBranch: nil, name: "main", persistence: 0, isRemote: false, isMerged: false, isTag: false, visual: GGBranchVis(orderGroup: 0, targetOrderGroup: nil, sourceOrderGroup: 3, termColor: 12, svgColor: "blue", column: 0), verticalSpan: GGBranchSpan(0,nil)),
            .init(target: OID(string: "1f990563cffcea707608a3a6687deb6487c2a753")!, mergeTarget: OID(string: "68b739db2492c1cd63a8b98e3d6caa70d435758c")!, sourceBranch: 0, targetBranch: 6, name: "ENG-1846", persistence: 6, isRemote: false, isMerged: true, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: 3, sourceOrderGroup: 0, termColor: 7, svgColor: "gray", column: 3), verticalSpan: GGBranchSpan(6,nil)),
            .init(target: OID(string: "354ab4ae660f90ac3bbbd38b2c3ab3f241191c6a")!, mergeTarget: OID(string: "44eedb215739af7bed10e72dd8265a64b8793f1d")!, sourceBranch: 0, targetBranch: 0, name: "aksh1t/ENG-1898", persistence: 6, isRemote: false, isMerged: true, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: 0, sourceOrderGroup: 0, termColor: 7, svgColor: "gray", column: 1), verticalSpan: GGBranchSpan(9,17)),
            .init(target: OID(string: "114db0bd655f650447ad7841aabe89d9aa2229a7")!, mergeTarget: OID(string: "68d193a9433c912cf98fd84628a7670a64a3f000")!, sourceBranch: 1, targetBranch: 1, name: "fork/ENG-1846", persistence: 6, isRemote: false, isMerged: true, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: 3, sourceOrderGroup: 3, termColor: 14, svgColor: "turquoise", column: 2), verticalSpan: GGBranchSpan(13,15)),
            .init(target: OID(string: "4021a8f960476cebf51f5daf31483fd9d6f0452a")!, mergeTarget: nil, sourceBranch: nil, targetBranch: nil, name: "git-graph-tests", persistence: 6, isRemote: false, isMerged: false, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: nil, sourceOrderGroup: nil, termColor: 7, svgColor: "gray", column: nil), verticalSpan: GGBranchSpan(nil,nil)),
            .init(target: OID(string: "44eedb215739af7bed10e72dd8265a64b8793f1d")!, mergeTarget: nil, sourceBranch: nil, targetBranch: nil, name: "ai/ENG-1700", persistence: 6, isRemote: true, isMerged: false, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: nil, sourceOrderGroup: nil, termColor: 7, svgColor: "gray", column: nil), verticalSpan: GGBranchSpan(nil,nil)),
            .init(target: OID(string: "e28c30f635cdd91b7fbd09dc56f06649b81a00b2")!, mergeTarget: nil, sourceBranch: 1, targetBranch: nil, name: "ai/ENG-1846", persistence: 6, isRemote: true, isMerged: false, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: nil, sourceOrderGroup: 3, termColor: 7, svgColor: "gray", column: 2), verticalSpan: GGBranchSpan(2,9)),
            .init(target: OID(string: "4021a8f960476cebf51f5daf31483fd9d6f0452a")!, mergeTarget: nil, sourceBranch: nil, targetBranch: nil, name: "ai/main", persistence: 6, isRemote: true, isMerged: false, isTag: false, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: nil, sourceOrderGroup: nil, termColor: 7, svgColor: "gray", column: nil), verticalSpan: GGBranchSpan(nil,nil)),
            .init(target: OID(string: "4021a8f960476cebf51f5daf31483fd9d6f0452a")!, mergeTarget: nil, sourceBranch: nil, targetBranch: nil, name: "tags/list", persistence: 7, isRemote: false, isMerged: false, isTag: true, visual: GGBranchVis(orderGroup: 3, targetOrderGroup: nil, sourceOrderGroup: nil, termColor: 10, svgColor: "green", column: nil), verticalSpan: GGBranchSpan(nil,nil)),
        ]

        for (index, expectedBranch) in expectedBranches.enumerated() {
            let branch = graph.allBranches[index]
            XCTAssertEqual(expectedBranch.target.debugOID, branch.target.debugOID)
            XCTAssertEqual(expectedBranch.mergeTarget?.debugOID, branch.mergeTarget?.debugOID)
            XCTAssertEqual(expectedBranch.sourceBranch, branch.sourceBranch)
            XCTAssertEqual(expectedBranch.targetBranch, branch.targetBranch)
            XCTAssertEqual(expectedBranch.name, branch.name)
            XCTAssertEqual(expectedBranch.persistence, branch.persistence)
            XCTAssertEqual(expectedBranch.isRemote, branch.isRemote)
            XCTAssertEqual(expectedBranch.isMerged, branch.isMerged)
            XCTAssertEqual(expectedBranch.isTag, branch.isTag)
            XCTAssertEqual(expectedBranch.visual.orderGroup, branch.visual.orderGroup)
            XCTAssertEqual(expectedBranch.visual.targetOrderGroup, branch.visual.targetOrderGroup)
            XCTAssertEqual(expectedBranch.visual.sourceOrderGroup, branch.visual.sourceOrderGroup)
            XCTAssertEqual(expectedBranch.visual.termColor, branch.visual.termColor)
            XCTAssertEqual(expectedBranch.visual.svgColor, branch.visual.svgColor)
            XCTAssertEqual(expectedBranch.visual.column, branch.visual.column)
            XCTAssertEqual(expectedBranch.verticalSpan.start, branch.verticalSpan.start)
            XCTAssertEqual(expectedBranch.verticalSpan.end, branch.verticalSpan.end)
        }
    }
}
