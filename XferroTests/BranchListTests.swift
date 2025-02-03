//
//  BranchListTests.swift
//  XferroTests
//
//  Created by Taha Bebek on 2/3/25.
//

import XCTest
@testable import Xferro

final class BranchListTests: XCTestCase {
    
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
    
    func testBranchList() throws {
        let repository = Fixtures.annoyRepository
        var stashes = [Stash]()

        try repository.stashes().get().forEach { stash in
            stashes.append(stash)
        }

        let branchIterator = BranchIterator(repo: repository, type: .local)

        var branches = [Branch]()
        while let branch = try? branchIterator.next()?.get() {
            branches.append(branch)
        }

        let headRef = try repository.HEAD().get()

        let head: BranchListViewModel.RepositoryInfo.Head = if let branchRef = headRef as? Branch {
            .branch(branchRef)

        } else if let tagRef = headRef as? TagReference {
            .tag(tagRef)
        } else if let reference = headRef as? Reference {
            .reference(reference)
        } else {
            fatalError()
        }

        let tags = repository.allTags().mustSucceed()
        let repositoryInfos = [
            BranchListViewModel.RepositoryInfo(
                branches: branches,
                stashes: stashes,
                tags: tags,
                head: head,
                url: repository.gitDir!
            )
        ]
        XCTAssertEqual(stashes.count, 1)
        XCTAssertEqual(branches.count, 4)
        XCTAssertEqual(tags.count, 1)
//        DataManager.save(repositoryInfos, filename: "repository_infos.json")
//        print("success")
    }
}
