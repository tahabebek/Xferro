//
//  ProjectsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Foundation
import Observation

@Observable final class ProjectsViewModel {
    var currentProject: Project?
    @ObservationIgnored var user: User

    init(user: User) {
        self.user = user
        self.currentProject = user.projects.currentProject
    }

    func userDidSelectFolder(_ url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let isGit = isFolderGit(url: url)
            let project = Project(isGit: isGit, url: url)
            user.projects.currentProject = project
            user.projects.recentProjects.insert(project)
            currentProject = project
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
