//
//  ProjectViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import Foundation
import Observation

@Observable
final class ProjectViewModel: ZoomAndPanViewModel {
    var project: Project
    var currentCommit: AnyCommit
    var peekCommit: AnyCommit?
    var tree: CommitTree?

    var idForDocument: String {
        "\(project.url.path)-view"
    }

    @ObservationIgnored var scrollWheelMonitor: Any?
    
    private var user: User
    private var commits: [AnyCommit] = []
    private var autoCommitRepo: Repository
    private var sourceRepo: Repository
    private var nodePositions: [String: CGPoint] = [:]

    init(user: User, project: Project) {
        self.user = user
        self.project = project
        let (autoCommitRepo, sourceRepo, initialCommit) = Self.createRepos(user: user, project: project)
        self.autoCommitRepo = autoCommitRepo
        self.sourceRepo = sourceRepo
        self.currentCommit = initialCommit
    }

    deinit {
    }

    private static func createRepos(user: User, project: Project) -> (autoCommitRepo: Repository, sourceRepo: Repository, initialCommit: AnyCommit) {
        do {
            RepoManager().reverseLog(project.url.path)
            let memoryRepo: Repository
            let diskRepoResult: Result<Repository, NSError>
            let diskRepo: Repository
            if project.isGit {
                memoryRepo = try Repository(sourcePath: project.url.path, shouldCopyFromSource: true, identity: user.commitIdentity)
                diskRepoResult = Repository.at(project.url)
            } else {
                memoryRepo = try Repository(sourcePath: project.url.path, shouldCopyFromSource: false, identity: user.commitIdentity)
                diskRepoResult = Repository.create(at: project.url)
            }
            switch diskRepoResult {
            case .success(let repository):
                diskRepo = repository
            case .failure(let error):
                fatalError(error.localizedDescription)
            }

            let headResult = memoryRepo.commit()
            guard case .success(let head) = headResult else {
                fatalError("Could not get head commit")
            }
            let initialCommit = AnyCommit(commit: head, kind: .manual, isMarked: false)
            return (autoCommitRepo: memoryRepo, sourceRepo: diskRepo, initialCommit: initialCommit)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func setScrollWheelMonitor(_ scrollWheelMonitor: Any?) {
        self.scrollWheelMonitor = scrollWheelMonitor
    }

    func restoreTapped(_ commit: AnyCommit) {
    }
    func manualCommitTapped(_ commit: AnyCommit) {
    }
    func autoCommitTapped(_ commit: AnyCommit) {
    }
    func nodePositionFor(_ id: String) -> CGPoint? {
        nodePositions[id]
    }
    func setNodePositions(_ positions: [String: CGPoint]) {
        nodePositions = positions
    }
    func mark(_ commit: AnyCommit, flag: Bool){
    }
}
