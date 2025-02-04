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
        self.user = user
    }

    func userDidSelectFolder(_ url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let isGit = isFolderGit(url: url)
            let project = Project(isGit: isGit, url: url)
            user.projects.append(project)
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
        let commitsViewModel = CommitsViewModel(repositories: repositories) { [weak self] url in
            guard let self else { return }
            userDidSelectFolder(url)
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
