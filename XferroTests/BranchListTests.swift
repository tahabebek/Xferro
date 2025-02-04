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
        let repositoryInfos = [
            try! repositoryInfo(from: Fixtures.annoyRepository),
            try! repositoryInfo(from: Fixtures.detachedHeadRepository),
            try! repositoryInfo(from: Fixtures.simpleRepository),
            try! repositoryInfo(from: Fixtures.mantleRepository),
            try! repositoryInfo(from: Fixtures.repositoryOnAnotherBranch),
            try! repositoryInfo(from: Fixtures.repositoryWithModifiedAndAddedFiles),
            try! repositoryInfo(from: Fixtures.repositoryInDetachedState),
            try! repositoryInfo(from: Fixtures.repositoryWithStatus),
        ]
//        DataManager.save(repositoryInfos, filename: "repository_infos.json")
//        print("success")
    }

//    func testCreateRepos() throws {
//        let repositories = [
//            Fixtures.annoyRepository,
//            Fixtures.detachedHeadRepository,
//            Fixtures.simpleRepository,
//            Fixtures.mantleRepository,
//            Fixtures.repositoryOnAnotherBranch,
//            Fixtures.repositoryWithModifiedAndAddedFiles,
//            Fixtures.repositoryInDetachedState,
//            Fixtures.repositoryWithStatus
//        ]
//        DataManager.save(repositories, filename: "repositories.json")
//        print("success")
//    }

    private func repositoryInfo(from repository: Repository) throws -> CommitsViewModel.RepositoryInfo {
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

        let head: CommitsViewModel.RepositoryInfo.Head = if let branchRef = headRef as? Branch {
            .branch(branchRef)

        } else if let tagRef = headRef as? TagReference {
            .tag(tagRef)
        } else if let reference = headRef as? Reference {
            .reference(reference)
        } else {
            fatalError()
        }

        let tags = repository.allTags().mustSucceed()
        return CommitsViewModel.RepositoryInfo(
            branches: branches,
            stashes: stashes,
            tags: tags,
            head: head,
            url: repository.gitDir!
        )
    }
}
