//
//  ProjectsViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa

class ProjectsViewController: NSViewController {
    let user: User
    var selectProjectViewController: SelectProjectViewController?

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentProject = user.projects.currentProject {
            showProjectView(project: currentProject)
        } else {
            showSelectProjectView(for: user)
        }
    }

    override func loadView() {
        let projectsView = NSView()
        projectsView.wantsLayer = true
        view = projectsView
    }

    private func showProjectView(project: Project) {
        let projectViewController = ProjectViewController(user: user)
        addChild(projectViewController)
        view.addSubview(projectViewController.view)

        projectViewController.view.translatesAutoresizingMaskIntoConstraints = false
        projectViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        projectViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        projectViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        projectViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    private func showSelectProjectView(for user: User) {
        let selectProjectViewController = SelectProjectViewController(user: user) { [weak self] url in
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let isGit = isFolderGit(url: url)
                let project = Project(isGit: isGit, url: url, commits: [])
                createInitialCommits(for: project)
                user.projects.currentProject = project
                user.projects.recentProjects.insert(project)
                if let selectVC = self.selectProjectViewController {
                    selectVC.removeFromParent()
                    selectVC.view.removeFromSuperview()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self else { return }
                    showProjectView(project: project)
                }
            }
        }

        addChild(selectProjectViewController)
        view.addSubview(selectProjectViewController.view)

        selectProjectViewController.view.translatesAutoresizingMaskIntoConstraints = false
        selectProjectViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        selectProjectViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        selectProjectViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        selectProjectViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.selectProjectViewController = selectProjectViewController
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

    private func createInitialCommits(for project: Project) {
        do {
            let memoryRepo = try InMemoryGit()
            var diskRepo: OnDiskGit

            if project.isGit {
                try memoryRepo.copyFromRepository(sourcePath: project.url.path)
                
            } else {
            }
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
}
