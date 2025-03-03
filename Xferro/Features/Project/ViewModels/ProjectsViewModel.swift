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

    init(user: User) {
        print("init ProjectsViewModel")
        self.user = user
    }

    deinit {
        print("deinit ProjectsViewModel")
    }

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

    func commitsViewModel() -> CommitsViewModel? {
        guard user.projects.isNotEmpty else { return nil }
        var repositories: [Repository] = []
        for project in user.projects {
            if let repository = try? Repository.at(project.url).get() {
                repositories.append(repository)
            }
        }
        guard repositories.isNotEmpty else { return nil }
        let commitsViewModel = CommitsViewModel(repositories: repositories, user: user) { [weak self] url, commitsViewModel in
            guard let self else { return }
            userDidSelectFolder(url, commitsViewModel: commitsViewModel)
        }
        return commitsViewModel
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
