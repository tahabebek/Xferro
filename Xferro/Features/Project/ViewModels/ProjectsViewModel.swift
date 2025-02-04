//
//  ProjectsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Foundation
import Observation

@Observable final class ProjectsViewModel {
    @ObservationIgnored var user: User
    var commitsViewModel: CommitsViewModel?

    init(user: User) {
        self.user = user
        self.reloadBranches()
    }

    func userDidSelectFolder(_ url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let isGit = isFolderGit(url: url)
            let project = Project(isGit: isGit, url: url)
            user.projects.append(project)
            self.reloadBranches()
        }
    }

    private func reloadBranches() {
        guard user.projects.isNotEmpty else { return }
        var repositories: [Repository] = []
        for project in user.projects {
            if let repository = try? Repository.at(project.url).get() {
                repositories.append(repository)
            }
        }
        guard repositories.isNotEmpty else { return }
        commitsViewModel = CommitsViewModel(repositories: repositories)
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
