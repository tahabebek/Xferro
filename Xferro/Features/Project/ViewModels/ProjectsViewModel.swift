//
//  ProjectsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Foundation
import Observation

@Observable final class ProjectsViewModel {
    var user: User

    init?(user: User?) {
        git_libgit2_init()
        guard let user else { return nil }
        self.user = user
        if user.projects.isNotEmpty {
            var repositories: [Repository] = []
            for project in user.projects {
                let repository = try! Repository.at(project.url).get()
                repositories.append(repository)
            }
            guard repositories.isNotEmpty else { return nil }
            let commitsViewModel = CommitsViewModel(repositories: repositories, user: user) { [weak self] url, commitsViewModel in
                guard let self else { return }
                userDidSelectFolder(url, commitsViewModel: commitsViewModel)
            }
            self.commitsViewModel = commitsViewModel
        } else {
            self.commitsViewModel = nil
        }
    }

    var commitsViewModel: CommitsViewModel?

    func userDidSelectFolder(_ url: URL, commitsViewModel: CommitsViewModel? = nil) {
        let isGit = isFolderGit(url: url)
        let project = Project(isGit: isGit, url: url)
        if user.addProject(project) {
            if let repository = try? Repository.at(project.url).get() {
                Task {
                    await commitsViewModel?.addRepository(repository)
                }
            }
        }
    }

    private func isFolderGit(url: URL) -> Bool {
        let result = Repository.isGitRepository(url: url)
        switch result {
        case .success(let isGit):
            if isGit {
                return true
            } else {
                return false
            }
        case .failure(let error):
            print("Error checking if folder is git: \(error.localizedDescription)")
            return false
        }
    }
}
