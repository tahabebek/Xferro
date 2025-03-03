//
//  RepositoryViewModel+GitWatcher.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Combine
import Foundation

extension RepositoryViewModel {
    func setupGitWatcher() -> GitWatcher {
        let headChangeSubject = PassthroughSubject<Void, Never>()
        let indexChangeSubject = PassthroughSubject<Void, Never>()
        let reflogChangeSubject = PassthroughSubject<Void, Never>()
        let localBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let remoteBranchesChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let tagsChangeSubject = PassthroughSubject<[GitWatcher.RefKey: Set<String>], Never>()
        let stashChangeSubject = PassthroughSubject<Void, Never>()

        self.headChangeObserver = headChangeSubject
            .sink { [weak self] in
                guard let self else { return }
                self.head = Head.of(repository)
                self.onGitChange?(.head(self))
            }

        self.indexChangeObserver = indexChangeSubject
            .sink { [weak self] in
                guard let self else { return }
//                print("index changed for repository \(repository.nameOfRepo)")
                self.status = StatusManager.shared.status(of: self.repository)
                self.onGitChange?(.index(self))
            }

        self.localBranchesChangeObserver = localBranchesChangeSubject
            .sink { [weak self] _ in
                guard let self else { return }
//                print("local branches changed for repository \(repository.nameOfRepo)")
                self.onGitChange?(.localBranches(self))
            }

        self.remoteBranchesChangeObserver = remoteBranchesChangeSubject
            .sink { [weak self] _ in
                guard let self else { return }
//                print("remote branches changed for repository \(repository.nameOfRepo)")
                self.onGitChange?(.remoteBranches(self))
            }

        self.tagsChangeObserver = tagsChangeSubject
            .sink { [weak self] _ in
                guard let self else { return }
//                print("tags changed for repository \(repository.nameOfRepo)")
                self.onGitChange?(.tags(self))
            }

        self.reflogChangeObserver = reflogChangeSubject
            .sink { [weak self] in
                guard let self else { return }
//                print("reflog changed for repository \(repository.nameOfRepo)")
                self.onGitChange?(.reflog(self))
            }

        self.stashChangeObserver = stashChangeSubject
            .sink { [weak self] in
                guard let self else { return }
//                print("stash changed for repository \(repository.nameOfRepo)")
                self.onGitChange?(.stash(self))
            }

        return GitWatcher(
            repository: repository,
            headChangePublisher: headChangeSubject,
            indexChangePublisher: indexChangeSubject,
            reflogChangePublisher: reflogChangeSubject,
            localBranchesChangePublisher: localBranchesChangeSubject,
            remoteBranchesChangePublisher: remoteBranchesChangeSubject,
            tagsChangePublisher: tagsChangeSubject,
            stashChangePublisher: stashChangeSubject
        )
    }
}
