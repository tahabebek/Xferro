//
//  Fixtures.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import ZipArchive
@testable import Xferro

final class Fixtures {

    // MARK: Lifecycle

    class var sharedInstance: Fixtures {
        enum Singleton {
            static let instance = Fixtures()
        }
        return Singleton.instance
    }

    init() {
        directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("com.xferro.Xferro")
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
    }

    // MARK: - Setup and Teardown

    let directoryURL: URL

    func setUp() {
        try! FileManager.createDirectory(atURL: directoryURL, withIntermediateDirectories: true, attributes: nil)

        let bundleIdentifier = String(format: "com.xferro.XferroTests")
        let bundle = Bundle(identifier: bundleIdentifier)!

        let zipURLs = bundle.urls(forResourcesWithExtension: "zip", subdirectory: nil)!

        for url in zipURLs {
            SSZipArchive.unzipFile(atPath: url.path, toDestination: directoryURL.path)
        }
    }

    func tearDown() {
        try? FileManager.removeItem(atURL: directoryURL)
    }

    // MARK: - Helpers

    func repository(named name: String) -> Repository {
        let url = directoryURL.appendingPathComponent(name, isDirectory: true)
        return Repository.at(url).value!
    }

    // MARK: - The Fixtures

    class var repositoryWithStatus: Repository {
        return Fixtures.sharedInstance.repository(named: "repository-with-status")
    }

    class var detachedHeadRepository: Repository {
        return Fixtures.sharedInstance.repository(named: "detached-head")
    }

    class var simpleRepository: Repository {
        return Fixtures.sharedInstance.repository(named: "simple-repository")
    }

    class var repositoryWithModifiedAndAddedFiles: Repository {
        return Fixtures.sharedInstance.repository(named: "repository-with-modified-and-added-files")
    }

    class var repositoryOnAnotherBranch: Repository {
        return Fixtures.sharedInstance.repository(named: "repository-on-another-branch")
    }

    class var repositoryInDetachedState: Repository {
        return Fixtures.sharedInstance.repository(named: "repository-in-detached-state")
    }

    class var mantleRepository: Repository {
        return Fixtures.sharedInstance.repository(named: "Mantle")
    }

    class var annoyRepository: Repository {
        return Fixtures.sharedInstance.repository(named: "ANNOY")
    }
}
