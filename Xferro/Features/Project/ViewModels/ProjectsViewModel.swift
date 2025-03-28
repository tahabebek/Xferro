//
//  ProjectsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Combine
import Foundation
import Observation

@Observable final class ProjectsViewModel {
    var user: User
    var commitsViewModel: CommitsViewModel!
    
    private var cancellables = Set<AnyCancellable>()
    
    init?(user: User?) {
        git_libgit2_init()
        guard let user else { return nil }
        self.user = user
        var repositories: [Repository] = []
        for project in user.projects {
            let repository = try! Repository.at(project.url).get()
            repositories.append(repository)
        }
        let commitsViewModel = CommitsViewModel(repositories: repositories, user: user) { [weak self] url, commitsViewModel in
            guard let self else { return }
            localRepositoryAdded(url: url)
        }
        self.commitsViewModel = commitsViewModel
        
        NotificationCenter.default.publisher(for: .newRepositoryAdded)
            .compactMap { $0.userInfo?[.repositoryURL] as? URL }
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                self?.newRepositoryAdded(url: url)
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .localRepositoryAdded)
            .compactMap { $0.userInfo?[.repositoryURL] as? URL }
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                self?.localRepositoryAdded(url: url)
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .repositoryCloneTapped)
            .compactMap { $0.userInfo?[.repositoryURL] as? URL }
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                self?.repositoryCloneTapped(url: url)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }

    func newRepositoryAdded(url: URL) {
        let isGit = isFolderGit(url: url)
        if !isGit {
            let repository = Repository.create(at: url).mustSucceed(url)
            repository.createEmptyCommit()
        }
        
        addProject(url: url)
    }

    func localRepositoryAdded(url: URL) {
        let isGit = isFolderGit(url: url)
        if isGit {
            addProject(url: url)
        } else {
            newRepositoryAdded(url: url)
        }
    }
    
    func repositoryCloneTapped(url: URL) {
    }
    
    private func addProject(url: URL) {
        let project = Project(isGit: true, url: url)
        if user.addProject(project) {
            if let repository = try? Repository.at(project.url).get() {
                Task {
                    await commitsViewModel.addRepository(repository)
                }
            } else {
                fatalError(.invalid)
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
